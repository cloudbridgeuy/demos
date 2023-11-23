# Backups Cross-Region y Cross-Account

El cliente requiere la configuración de respaldos de una base de datos RDS entre cuentas y entre regiones. En total, tiene 5 bases de datos que deben respaldarse de esta manera, dos de las cuales están encriptadas con la clave KMS por defecto de `aws/rds` gestionada por AWS.

> El uso de la clave `aws/rds` para la encriptación de las bases de datos impide el uso de AWS Backups para la solución.

Ante esta situación, se propone alcanzar el mismo nivel de respaldo aprovechando las funcionalidades de compartir y copiar snapshots de RDS. Al crear una copia de un snapshot, se puede seleccionar una nueva clave para encriptarlo. Esto permite utilizar diferentes claves para asegurar la protección de los snapshots entre cuentas.

## Prueba de Concepto

La prueba de concepto se centrará en dos regiones: `us-east-1` y `us-west-1`, y usará dos cuentas de AWS: `primary` y `secondary`, ambas en las mismas regiones.

Para llevar a cabo la prueba de concepto, necesitaremos los siguientes recursos iniciales:

- Una base de datos RDS encriptada con la clave por defecto `aws/rds`.
- Una clave de encriptación KMS gestionada por nosotros, compartida con la segunda cuenta y replicada en la cuenta secundaria.

### Preguntas a responder

- ¿Cómo podemos reaccionar ante la creación de un nuevo snapshot en RDS para copiarlo a la región de contingencia?
- ¿Cómo podemos reaccionar al finalizar la copia del snapshot en la región de contingencia para realizar la copia en la cuenta de contingencia?

### Procedimiento

#### Creación de los recursos iniciales

Las cuentas `primary` y `secondary` se crean a través de AWS Organizations. Ambas contarán con un usuario llamado `dba` con permisos de administrador.

La red a utilizar será la VPC por defecto que viene preconfigurada en todas las regiones. Se utilizará una instancia `micro` para lanzar la base de datos. Luego, se creará la clave KMS que se compartirá entre regiones y cuentas.

Para simplificar la ejecución de comandos en las cuentas, se generaron los siguientes perfiles:

- `cloudbridge-dba-primary`: Cuenta principal en `us-east-1`.
- `cloudbridge-dba-secondary`: Cuenta secundaria en `us-east-2`.
- `cloudbridge-dba-primary-2`: Cuenta principal en `us-east-2`.

Se puede acceder a cada uno de estos perfiles utilizando la opción `--profile` de la CLI de AWS. Un paso adicional es crear un alias para cada perfil para evitar tener que escribir el nombre del perfil cada vez que queramos ejecutar un comando:

```bash
alias primary="aws --profile cloudbridge-dba-primary"
alias secondary="aws --profile cloudbridge-dba-secondary"
alias primary2="aws --profile cloudbridge-dba-primary-2"
```

> Recordar que para refrescar los tokens de acceso se puede ejecutar el comando: `aws sso login --profile $PROFILE_NAME`

Estos `alias` se pueden utilizar igual que la CLI de AWS:

```bash
primary sts get-caller-identity
{
    "UserId": "AROA257UCWxxxxxxxxxxx:dba",
    "Account": "7515xxxxxxxx",
    "Arn": "arn:aws:sts::7515xxxxxxxx:assumed-role/AWSReservedSSO_AdministratorAccess_b12c399cxxxxxxxx/dba"
}
```

Para acceder a la base de datos, necesitaremos una instancia que funcione como bastión, ya que las bases de RDS no pueden ser accedidas desde Internet. Para ello, crearemos una nueva clave SSH.

```bash
ssh-keygen -t rsa -b 4096 -C "$EMAIL" -f "$SSH_KEY_PATH"
primary ec2 import-key-pair --key-name "$SSH_KEY_NAME" --public-key-material "fileb://$SSH_KEY_PATH.pub"
```

> Se asume que las variables `EMAIL`, `SSH_KEY_PATH`, etc., están definidas en la sesión actual.

Para verificar que la clave se ha creado correctamente:

```bash
primary ec2 describe-key-pairs --query 'KeyPairs[*].[KeyName]' --output text
```

Usaremos `CloudFormation` para el despliegue de los recursos. [Este template](./cold-start.yaml) se invocará con una serie de parámetros como la `subnet` donde se creará la base de datos y la clave para el servidor bastión que tendrá acceso a la base de datos.

Para listar las subredes disponibles:

```bash
primary ec2 describe-subnets \
  | jq -r '.Subnets | map([.SubnetId, .VpcId, .CidrBlock, .AvailabilityZone]) | (["Subnet ID", "VPC ID", "CIDR Block", "Availability Zone"], .[]) | @csv' \
  | column -t -s,
```

Para obtener la última versión de la imagen de Amazon Linux 2 para nuestro servidor bastión en nuestra región:

```bash
aws ec2 describe-images \
    --region $PRIMARY_AWS_REGION \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text
```

Las variables de CloudFormation se almacenarán en un documento JSON con el siguiente formato:

```json
[
  {
    "ParameterKey": "DBPassword",
    "ParameterValue": "${DB_PASSWORD}"
  },
  {
    "ParameterKey": "DBName",
    "ParameterValue": "cloudbridgeuy"
  },
  {
    "ParameterKey": "DBUser",
    "ParameterValue": "cloudbridgeuy"
  },
  {
    "ParameterKey": "DBSubnetGroupName",
    "ParameterValue": "cloudbridgeuy"
  },
  {
    "ParameterKey": "VpcId",
    "ParameterValue": "vpc-057f79294a5e3c1f4"
  },
  {
    "ParameterKey": "SubnetId",
    "ParameterValue": "subnet-05de8215c7985eb29"
  },
  {
    "ParameterKey": "KeyName",
    "ParameterValue": "id_rsa_cloudbridge_dba_rsa"
  },
  {
    "ParameterKey": "ImageId",
    "ParameterValue": "ami-076c7acfc9e8ee57d"
  }
]
```

Es recomendable generar un archivo de estos para cada entorno a soportar.

Podemos desplegar el `stack` utilizando el script dentro de `scripts/cli.sh`.

```bash
./scripts/cli.sh cold-start create
```

> El comando `--help` ofrece más opciones sobre cómo utilizar este script.

El proceso de creación de la base de datos toma varios minutos. Una vez finalizado, podemos implementar los recursos que reaccionarán ante eventos generados por RDS.

Ahora podemos crear los recursos relacionados con la gestión de eventos.

```bash
./scripts/cli.sh events create
```

> Actualmente, el template `events` incluye la creación de la clave privada KMS Multi-región y el rol que utilizará la función Lambda. Sería mejor trasladar todo esto a un CloudFormation específico.

Finalmente, necesitamos crear los recursos en la cuenta de contingencia. Este template requiere parámetros adicionales que debemos obtener del resultado del despliegue del template `events`. Para facilitar la obtención de estos valores, se proporciona el siguiente comando:

```bash
./scripts/cli.sh events status
```

Dentro de la clave `Outputs`, encontraremos los valores de:

- `LambdaFunctionArn`: ARN de la función Lambda que copiará los snapshots.
- `PrincipalKmsKeyArn`: ARN de la clave KMS principal.

Estos valores se deben pasar al template `cross-region`.

> Para facilitar el despliegue, el comando `create` de `cross-region` busca estos valores automáticamente si no se proporcionan como opciones adicionales.

```bash
./scripts/cli.sh cross-region create
```

> Este segundo template se desplegará en la cuenta principal pero en la región de contingencia. En la demo, estamos utilizando `us-east-2`.

Una vez desplegados todos los templates, podemos forzar la creación de un `snapshot` de la base de datos para comprobar si se realiza la copia.

```bash
demo snapshots create
```

Este comando espera a que finalice el proceso de snapshot. Una vez completado, se ejecuta el evento correspondiente que termina llamando a nuestra función y ejecuta la copia. Podemos verificar su funcionamiento revisando los logs de la función.

```bash
demo events logs
```

Una salida exitosa debería verse de la siguiente manera:

```txt
INIT_START Runtime Version: python:3.8.v33      Runtime Version ARN: arn:aws:lambda:us-east-1::runtime:353a31d9fb2c7cac8474d278a6cf08824c7f87f698d61d1df2c128fc25a48d43

START RequestId: fc6c9419-4d8c-4a5a-bd8e-4226ddc894d5 Version: $LATEST

Procesando nuevo evento

Snapshot ARN: arn:aws:rds:us-east-1:751594288501:snapshot:cross-region-cross-account-rds-backups-dev-snapshot-1700446618

Snapshot Name: cross-region-cross-account-rds-backups-dev-snapshot-1700446618

Copia de snapshot finalizada con éxito

END RequestId: fc6c9419-4d8c-4a5a-bd8e-4226ddc894d5

REPORT RequestId: fc6c9419-4d8c-4a5a-bd8e-4226ddc894d5  Duration: 2804.43 ms    Billed Duration: 2805 ms        Memory Size: 128 MB     Max Memory Used: 70 MB  Init Duration: 262.28 ms
```

### Cross-Account

Para la copia de snapshots entre cuentas tenemos que realizar pasos únicos para permitir que desde la región de contingencia podramos enviar eventos a la cuenta de contingencia. Esto lo necesitamos para poder avisarle a la misma que ya puede copiar el snapshot compartido. Lamentablemente AWS no proporciona un evento que se lanze cuando otra cuenta comparte un `snapshot` con la misma.

Es recomendable realizar estos pasos utilizando la consola de administración de AWS.

Primero, ir a EventBridge. Luego `Event Buses` y seleccionar el bus `default`. En la pestaña `Permissions`, seleccionar `Manage permissions` y agregar la nueva política según el siguiente template:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "AllowAccountToPutEvents",
    "Effect": "Allow",
    "Principal": {
      "AWS": "${PRIMARY_ACCOUNT_ID}"
    },
    "Action": "events:PutEvents",
    "Resource": "arn:aws:events:${AWS_REGION}:"${ACCOUNT_ID}:event-bus/default"
  }]
}
```

Ahora tenemos que ir a EventBridge en la cuenta principal.

> **Importante**: Recordar que tenemos que utilizar la misma región en ambos casos. Específicamente, debemos usar la región de _contingencia_.

Vamos a crear una nueva regla que se va a encargar de recibir los eventos y los va a enviar a la cuenta de contingencia. Para esto, debemos crearlo con el siguiente patrón.

```json
{
  "account": ["${PRIMARY_ACCOUNT_ID}"],
  "region": ["${AWS_REGION}"],
  "source": ["atos.rds"],
  "detail-type": ["RDS DB Shared Snapshot Event"],
  "detail": {
    "SourceType": ["SNAPSHOT"],
    "EventID": ["CROSS-ACCOUNT-SHARED-SNAPSHOT"]
  }
}
```

Esta regla respondera a eventos customizados que tengan una forma similar a la siguiente:

```json
{
  "version": "0",
  "id": "844e2571-85d4-695f-b930-0153b71dcb42",
  "detail-type": "RDS DB Shared Snapshot Event",
  "source": "atos.rds",
  "account": "751594288501",
  "time": "2018-10-06T12:26:13Z",
  "region": "us-east-2",
  "resources": [
    "arn:aws:rds:us-east-2:751594288501:snapshot:rds:snapshot-replica-2018-10-06-12-24"
  ],
  "detail": {
    "EventCategories": ["shared"],
    "SourceType": "SNAPSHOT",
    "SourceArn": "arn:aws:rds:us-east-1:751594288501:snapshot:rds:snapshot-replica-2018-10-06-12-24",
    "Date": "2018-10-06T12:26:13.882Z",
    "SourceIdentifier": "rds:snapshot-replica-2018-10-06-12-24",
    "Message": "Manual shared snapshot",
    "EventID": "CROSS-ACCOUNT-SHARED-SNAPSHOT"
  }
}
```

La razón por la cual creamos esta regla a través de la consola de administración es para simplificar el proceso de creación de los roles necesarios para que funcione, dado que AWS lo va a generar por nosotros.

## Conclusiones

El proceso de copia automática de snapshots entre regiones es factible. Solo es necesario:

1. Verificar el formato del evento de creación de `snapshot` de RDS para que la función se ejecute correctamente.
2. Crear la clave de KMS en la región principal y crear una copia en la región secundaria. Esto se traduce en una clave KMS multi-región con una `KeyReplica` en la región secundaria.
3. Otorgar permisos suficientes a la función Lambda para que pueda hacer uso de la clave KMS.

Este proceso puede aplicarse tanto a snapshots manuales como automáticos.
