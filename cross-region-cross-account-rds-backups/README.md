# Backups Cross-Region y Cross-Account

El cliente requiere la configuración de respaldos de una base de datos RDS entre
cuentas y entre regiones. En total, cuenta con 5 bases de datos que debe
respaldar en esta modalidad, dos de las cuales se encuentran encriptadas con la
llave KMS por defecto de `aws/rds` gestionada por AWS.

> El uso de la llave `aws/rds` para la encriptación de las bases de datos hace
> imposible el uso de AWS Backups para la solución.

Dada esta situación, se busca conseguir el mismo nivel de respaldo explotando
las funcionalidades de compartir y copiar snapshots de RDS. Al momento de crear
una copia de un snapshot, podemos elegir una nueva llave para encriptar el
mismo. Esto nos permite utilizar distintas llaves para mantener la seguridad de
los snapshots entre cuentas.

## Prueba de Concepto

La prueba de concepto estará centrada en dos regiones: `us-east-1`
y `us-west-1`, y utilizará dos cuentas de AWS: `primary` y `secondary` utilizando
las mismas regiones.

Para realizar la prueba de concepto vamos a necesitar ciertos recursos iniciales
los siguientes recursos:

- Una base de datos RDS encriptada con la llave por defecto `aws/rds`.
- Una llave de encriptación KMS gestionada por nosotros, compartida con la
  segunda cuenta y copiada con la cuenta secundaria.

### Preguntas a responder

- ¿Como podemos reaccionar ante la creación de una nueva snapshot en RDS para
  copiar la misma a la región de contingencia?
- ¿Cómo podemos reaccionar al finalizado de la copia del snapshot en la región
  de contingencia para realizar la copia a la cuenta de contingencia?

### Procedimiento

#### Creación de los recursos iniciales.

Las cuentas `primary` y `secondary` se crean a traves de AWS Organizations.
Ambas contarán con un usuario llamado `dba` con permisos de adminstrador sobre
ambas.

La red a utilizar será la VPN por defecto que viene inicializada en todas las
regiones. Una instancia `micro` será utilizada para lanzar la base de datos.
Luego se creará la llave KMS que se compartira entre regiones y otras cuentas.

Para simplificar la ejecución de comandos en las tres cuents se generarón los
siguientes perfiles:

- `cloudbridge-dba-primary`: Cuenta principal en `us-east-1`
- `cloudbridge-dba-secondary`: Cuenta secundaria en `us-east-2`
- `cloudbridge-dba-primary-2`: Cuenta principal en `us-east-2`.

Podemos acceder a cada uno de estos perfiles utilizando la opción `--profile` de
la CLI de `aws`. Un paso adicional que podemos dar es crear un alias para cada
uno de estos pefiles y de esa manera evitar tener que tipear el nombre del
perfil cada vez que queremos ejecutar un comando:

```bash
alias primary="aws --profile cloudbridge-dba-primary"
alias secondary="aws --profile cloudbridge-dba-secondary"
alias primary2="aws --profile cloudbridge-dba-primary-2"
```

Podemos utilizar estos `alias` igual que si fuera la cli de `aws`:

```bash
primary sts get-caller-identity
{
    "UserId": "AROA257UCWxxxxxxxxxxx:dba",
    "Account": "7515xxxxxxxx",
    "Arn": "arn:aws:sts::7515xxxxxxxx:assumed-role/AWSReservedSSO_AdministratorAccess_b12c399cxxxxxxxx/dba"
}
```

Otro elemento que necesitaremos para acceder a la base de datos es una pequeña
base de datos que oficie como bastión, dado que las bases de RDS no podrán ser
accedidas desde Internet. Para poder acceder vamos a tener que crear una nueva
llave SSH.

```bash
ssh-keygen -t rsa -b 4096 -C "$EMAIL" -f "$SSH_KEY_PATH"
primary ec2 import-key-pair --key-name "$SSH_KEY_NAME" --public-key-material "fileb://$SSH_KEY_PATH.pub"
```

> Suponemos que las variables `EMAIL`, `SSH_KEY_PATH`, etc. están cargadas en
> nuestra sesión actual.

Podemos usar el siguiente comando para verificar que la llave se ha creado
correctamente.

```bash
primary ec2 describe-key-pairs --query 'KeyPairs[*].[KeyName]' --output text
```

Utilizaremos `CloudFormation` para el despliegue de los recursos. [Este
template](./cold-start.yaml) lo vamos a tener que llamar con una serie de
parámetros como la `subnet` donde se creara la base de datos, y la llave que
necesitaremos para el servidor bastión que tendrá accesso a la base de datos.

Para poder ver una lista de las subredes disponibles:

```bash
primary ec2 describe-subnets \
  | jq -r '.Subnets | map([.SubnetId, .VpcId, .CidrBlock, .AvailabilityZone]) | (["Subnet ID", "VPC ID", "CIDR Block", "Availability Zone"], .[]) | @csv' \
  | column -t -s,
```
