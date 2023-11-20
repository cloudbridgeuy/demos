# Backups Cross-Region y Cross-Account

El cliente requiere la configuración de respaldos de una base de datos RDS entre cuentas y entre regiones. En total, cuenta con 5 bases de datos que debe respaldar en esta modalidad, dos de las cuales se encuentran encriptadas con la llave KMS por defecto de `aws/rds` gestionada por AWS.

> El uso de la llave `aws/rds` para la encriptación de las bases de datos hace imposible el uso de AWS Backups para la solución.

Dada esta situación, se busca conseguir el mismo nivel de respaldo explotando las funcionalidades de compartir y copiar snapshots de RDS. Al momento de crear una copia de un snapshot, podemos elegir una nueva llave para encriptar el mismo. Esto nos permite utilizar distintas llaves para mantener la seguridad de los snapshots entre cuentas.

## Prueba de Concepto

La prueba de concepto estará centrada en dos regiones: `us-east-1` y `us-west-1`, y utilizará dos cuentas de AWS: `primary` y `secondary` utilizando las mismas regiones.

Para realizar la prueba de concepto vamos a necesitar ciertos recursos iniciales los siguientes recursos:

- Una base de datos RDS encriptada con la llave por defecto `aws/rds`.
- Una llave de encriptación KMS gestionada por nosotros, compartida con la segunda cuenta y copiada con la cuenta secundaria.

### Preguntas a responder

- ¿Como podemos reaccionar ante la creación de una nueva snapshot en RDS para copiar la misma a la región de contingencia?
- ¿Cómo podemos reaccionar al finalizado de la copia del snapshot en la región de contingencia para realizar la copia a la cuenta de contingencia?

### Procedimiento

#### Creación de los recursos iniciales.

Las cuentas `primary` y `secondary` se crean a traves de AWS Organizations. Ambas contarán con un usuario llamado `dba` con permisos de adminstrador sobre ambas.

La red a utilizar será la VPN por defecto que viene inicializada en todas las regiones. Una instancia `micro` será utilizada para lanzar la base de datos. Luego se creará la llave KMS que se compartira entre regiones y otras cuentas.

Para simplificar la ejecución de comandos en las tres cuents se generarón los siguientes perfiles:

- `cloudbridge-dba-primary`: Cuenta principal en `us-east-1`
- `cloudbridge-dba-secondary`: Cuenta secundaria en `us-east-2`
- `cloudbridge-dba-primary-2`: Cuenta principal en `us-east-2`.

Podemos acceder a cada uno de estos perfiles utilizando la opción `--profile` de la CLI de `aws`. Un paso adicional que podemos dar es crear un alias para cada uno de estos pefiles y de esa manera evitar tener que tipear el nombre del perfil cada vez que queremos ejecutar un comando:

```bash
alias primary="aws --profile cloudbridge-dba-primary"
alias secondary="aws --profile cloudbridge-dba-secondary"
alias primary2="aws --profile cloudbridge-dba-primary-2"
```

> Recordar que para poder refrescar los tokens de acceso podemos correr el siguiente comando: `aws sso login --profile $PROFILE_NAME`

Podemos utilizar estos `alias` igual que si fuera la cli de `aws`:

```bash
primary sts get-caller-identity
{
    "UserId": "AROA257UCWxxxxxxxxxxx:dba",
    "Account": "7515xxxxxxxx",
    "Arn": "arn:aws:sts::7515xxxxxxxx:assumed-role/AWSReservedSSO_AdministratorAccess_b12c399cxxxxxxxx/dba"
}
```

Otro elemento que necesitaremos para acceder a la base de datos es una pequeña base de datos que oficie como bastión, dado que las bases de RDS no podrán ser accedidas desde Internet. Para poder acceder vamos a tener que crear una nueva llave SSH.

```bash
ssh-keygen -t rsa -b 4096 -C "$EMAIL" -f "$SSH_KEY_PATH"
primary ec2 import-key-pair --key-name "$SSH_KEY_NAME" --public-key-material "fileb://$SSH_KEY_PATH.pub"
```

> Suponemos que las variables `EMAIL`, `SSH_KEY_PATH`, etc. están cargadas en nuestra sesión actual.

Podemos usar el siguiente comando para verificar que la llave se ha creado correctamente.

```bash
primary ec2 describe-key-pairs --query 'KeyPairs[*].[KeyName]' --output text
```

Utilizaremos `CloudFormation` para el despliegue de los recursos. [Este template](./cold-start.yaml) lo vamos a tener que llamar con una serie de parámetros como la `subnet` donde se creara la base de datos, y la llave que necesitaremos para el servidor bastión que tendrá accesso a la base de datos.

Para poder ver una lista de las subredes disponibles:

```bash
primary ec2 describe-subnets \
  | jq -r '.Subnets | map([.SubnetId, .VpcId, .CidrBlock, .AvailabilityZone]) | (["Subnet ID", "VPC ID", "CIDR Block", "Availability Zone"], .[]) | @csv' \
  | column -t -s,
```

Para obtener la última versión de la imágen de Amazon Linux 2 para utilizar en nuestro servidor bastión en nuestra región podemos usar el siguiente comando:

```bash
aws ec2 describe-images \
    --region $PRIMARY_AWS_REGION \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text
```

Las variables de CloudFormation a utilizar tienen que ser almacenadas en un documento JSON con el siguiente formato:

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

Es conveniente generar un archivo de estos para cada ambiente a soportar.

Podemos desplegar el `stack` utilizando el script dentro de `scripts/cli.sh`.

```bash
./scripts/cli.sh cold-start create
```

> Utilizando el comando `--help` podemos encontrar más opciones sobre como utilizar este script.

El proceso de creación de base de datos dura varios minutos. Una vez finalizado, podemos levantar los recursos encargados de raccionar ante eventos generados por RDS.

Ahora podemos crear los recursos relacionados a la gestión de eventos.

```bash
./scripts/cli.sh events create
```

> Actualmente el template `events` engloba la creación de la llave privada KMS Multi-región y el rol qur utilizará la función Lambda. Sería mejor mover todos estos a un CloudFormation especifico.

Por último, necesitamos crear los recursos en la cuenta de contingencia. Este template require de parámetros adicionales que tenemos que obtener del resultado del despliegue del template `events`. Para simplificar la obtención de estos valore se expone el siguiente comando:

```bash
./scripts/cli.sh events status
```

Dentro de la llave `Outputs` podremos encontrar los valores de:

- `LambdaFunctionArn`: ARN de la función lambda que copiara los snaphots.
- `PrincipalKmsKeyArn`: ARN de la llave KMS principal.

Estos valores se los tenemos que pasar al template `cross-region`.

> Para simplificar el despliegue del mismo, el comando `create` de `cross-region` busca estos valores automaticamente si no se proveen como opciones adicionales.

```bash
./scripts/cli.sh cross-region create
```

> Este segundo template se desplegará en la cuenta principal pero en la región de contingencia. En la demo estamos utilizando `us-east-2`.

Una vez que todos los templates son desplegados podemos forcar la creación de un `snapshot` de la base de datos para ver si se efectura la copia.

```bash
demo snapshots create
```

Este comando espera que termine el proceso de snapshot. Una vez finalizado, el evento correspondiente se ejecuta que termina llamando a nuestra función y ejectuta la copia. Podemos verificar su funcionamiento verificando los logs de la función.

```bash
demo events logs
```

Una salida exitosa debería verse similar a la siguiente:

```txt
INIT_START Runtime Version: python:3.8.v33      Runtime Version ARN: arn:aws:lambda:us-east-1::runtime:353a31d9fb2c7cac8474d278a6cf08824c7f87f698d61d1df2c128fc25a48d43

START RequestId: fc6c9419-4d8c-4a5a-bd8e-4226ddc894d5 Version: $LATEST

Procesando nuevo evento

Snapshot ARN: arn:aws:rds:us-east-1:751594288501:snapshot:cross-region-cross-account-rds-backups-dev-snapshot-1700446618

Snapshot Name: cross-region-cross-account-rds-backups-dev-snapshot-1700446618

Copia de snapshot finalizada con exito

END RequestId: fc6c9419-4d8c-4a5a-bd8e-4226ddc894d5

REPORT RequestId: fc6c9419-4d8c-4a5a-bd8e-4226ddc894d5  Duration: 2804.43 ms    Billed Duration: 2805 ms        Memory Size: 128 MB     Max Memory Used: 70 MB  Init Duration: 262.28 ms
```

## Conclusiones

El proceso de copia de snapshots entre regiones de forma automática es posible. Lo único que es necesario es:

1. Veríficar el formato del evento de creación de `snapshot` de RDS para que la función se ejecute correctamente.
2. Crear la llave de KMS en la región principal y crear un copia en la región secundaria. Esto se traduce a una llave KMS multi-región con una `KeyReplica` en la región secundaria.
3. Darle permisos suficientes a la función Lambda para que puede hacer uso de la llave KMS.

Este proceso se puede utilizar para reaccionar ante snapshots manuales o automáticos.
