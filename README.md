# Search Management UI (SMUI) - Manual version 2.0.3

![SMUI v1.5.0 screenshot](20190103_screenshot_SMUI_v1-5-0.png)

SMUI is a tool for managing Solr-based onsite search. It provides a web user interface for maintainig rules for query rewriting based on the Querqy Solr plugin for query rewriting. Please see [here](https://github.com/renekrie/querqy) for the installation of Querqy.

## INSTALLATION

Please follow the above steps in this order.

### Step 1: Install RPM

Example script (command line):

```
rpm -i PATH/search-management-ui-VERSION.noarch.rpm
```

Note:
* Ensure the user running the search-management-ui (e.g. `smui`) has read permission to the necessary files (e.g. binary JAR files) and write permission for logs, temp file as well as application's PID (see "Step 3").
* Ensure `search-management-ui` service is being included to your Server's start up sequence (e.g. `init.d`).
* It might be necessary to execute command with root rights.

### Step 2: Create and configure database (SQL level)

Create MariaDB- or MySQL-database, user and assign according permissions. Example script (SQL):

```
CREATE USER 'smui'@'localhost' IDENTIFIED BY 'smui';
CREATE DATABASE smui;
GRANT ALL PRIVILEGES ON smui.* TO 'smui'@'localhost' WITH GRANT OPTION;
```

Supported (tested) databases:

In principal SMUI database connection implementation is based on JDBC as well as only standard SQL is used, so technically every database management system supported by JDBC should be supported by SMUI as well. However as database management systems potentially come with specific features, SMUI explicity is tested (and/or productively used) only with the following database management systems:

* MySQL
* MariaDB
* PostgreSQL

#### Migrate pre 2.0.0 database versions
As of version 2 of SMUI various database management systems are supported. With that, the daabase schema changed. To migrate the previous MySQL- or MariaDB-data to be compatible with SMUI version 2 you can use the following script, e.g.:

```
tbd
```

### Step 3: Configure runtime and application

#### Configure runtime (shell level)

The following settings can be made on (JVM) runtime level:

variable name | description
--- | ---
`SMUI_CONF_PID_PATH` | Path to Play 2.6 PID file.
`SMUI_CONF_LOG_BASE_PATH` | Base path for the logs to happen.
`SMUI_CONF_LOGBACK_XML_PATH` | logback.xml config file path.
`SMUI_CONF_APP_CONF` | application.conf config file path.
`SMUI_CONF_HTTP_PORT` | Application's HTTP port.

If present, the following file can manipulate these variables:

```
/srv/search-management-ui/service-start-config.sh
```

This config script filename is hard coded and will be called by the start script, if the file is present. Example script:

```
#!/usr/bin/env bash

SMUI_CONF_PID_PATH=/srv/var/run/search-management-ui/play.pid
SMUI_CONF_LOG_BASE_PATH=/srv/var/log
SMUI_CONF_LOGBACK_XML_PATH=${app_home}/../conf/logback.xml
SMUI_CONF_APP_CONF=${app_home}/../conf/application.conf
SMUI_CONF_HTTP_PORT=8080
```

If no config script is present, the startup script will take (in this order):

1. values of above's variables given in the execution environment
2. if none given, defaults configured in the startup script (e.g. `addJava "-DLOG_BASE_PATH=/var/log`),

#### Configure application (Play 2.6 configuration level)

The configuration file for the application by default is located under:

```
/usr/share/search-management-ui/conf/application.conf
```

An extension to this file overwriting specific settings should be defined in an own `smui-prod.conf`, e.g.:

Important: This config file - extending the existing settings - must firstly include those settings!

```
include "application.conf"

db.default.url="jdbc:mysql://localhost/smui?autoReconnect=true&useSSL=false"
db.default.username="smui"
db.default.password="smui"

smui2solr.SRC_TMP_FILE="/PATH/TO/TMP/FILE.tmp"
smui2solr.DST_CP_FILE_TO="PATH/TO/SOLR/CORE/CONF/rules.txt"
smui2solr.SOLR_HOST="localhost:8983"

# optional feature toggles (see below)

play.http.secret.key="generated application secret"
```

Database URL and credentials alternatively can be passed as environment variables (e.g. `SMUI_DB_URL`, see `conf/application.conf`). Your `smui-prod.conf` in this case leaves the according config lines empty. This is especially useful when instantiating SMUI in a `docker`, `docker-compose` or cloud environment.

The following sections describe application configs in more detail.

##### Configure basic settings

The following settings can (and should) be overwritten on application.conf in your own `smui-prod.conf` level:

conf key | description
--- | ---
`db.default.*` | Login host and credentials to the database (connection string)
`smui2solr.SRC_TMP_FILE` | Path to temp file (when rules.txt generation happens)
`smui2solr.DST_CP_FILE_TO` | Path to productive querqy rules.txt (within Solr context)
`smui2solr.SOLR_HOST` | Solr host
`play.http.secret.key` | Encryption key for server/client communication (Play 2.6 standard)

##### Configure Feature Toggle (application behaviour)

Optional. The following settings in the `application.conf` define its (frontend) behaviour:

conf key | description | default
--- | --- | ---
`toggle.ui-concept.updown-rules.combined` | Show UP(+++) fields instead of separated rule and intensity fields. | `true`
`toggle.ui-concept.all-rules.with-solr-fields` | Offer a separated "Solr Field" input to the user (UP/DOWN, FILTER). | `true`
`toggle.rule-deployment.auto-decorate.export-hash` | With every exported search input, add an additional DECORATE line that identifies export date and hash (over all rules). | `false`
`toggle.rule-deployment.split-decompound-rule-txt` | Separate decompound synonyms (SOME* => SOME $1) into an own rules.txt file. WARNING: Activating this results in the need of having the second special-purpose-DST_CP_FILE_TO configured (see below). Temp file path for this purpose will be generated by adding a `-2` to `smui2solr.SRC_TMP_FILE`. | `false`
`toggle.rule-deployment.split-decompound-rule-txt-DST_CP_FILE_TO` | Path to productive querqy decompound-rules.txt (within Solr context). | ``
`toggle.rule-deployment.pre-live.present` | Make separated deployments pre-live vs. live possible. | `false`
`toggle.rule-deployment.custom-script` | If set to `true` the below custom script (path) is used for deploying the rules.txt files. | `false`
`toggle.rule-deployment.custom-script-SMUI2SOLR-SH_PATH` | Path to an optional custom script (see above). | ``

##### Configure Authentication

SMUI is shipped with HTTP Basic Auth support. Basic Auth can be turned on in the extension by configuring an `smui.authAction` in the config file, e.g.:

```
# For Basic Auth authentication, use SMUI's BasicAuthAuthenticatedAction (or leave it blanked / commented out for no authentication), e.g.:
smui.authAction = controllers.auth.BasicAuthAuthenticatedAction
smui.BasicAuthAuthenticatedAction.user = smui_user
smui.BasicAuthAuthenticatedAction.pass = smui_pass
```

This is telling every controller method (Home and ApiController) to use the according authentication method as well as it tells SMUI's `BasicAuthAuthenticatedAction` username and password it should use. You can also implement a custom authentication action and tell SMUI to decorate its controllers with that, e.g.:

```
smui.authAction = myOwnPackage.myOwnAuthenticatedAction
```

See "Developing Custom Authentication" for details.


#### First time start the application

Then first time start the service. Example script (command line):

```
search-management-ui &
```

Or via `service` command, or automatic startup after reboot respectively. Now navigate to SMUI application in the browser (e.g. `http://smui-server:9000/`) and make sure you see the application running (the application needs to bootstrap the database scheme).

### Step 4: Create initial data (SQL level)

Once the database scheme has been established, the initial data can be inserted.

#### Solr Collections to maintain Search Management rules for

There must exist a minimum of 1 Solr Collection, that Search Management rules are maintained for. This must be created before the application can be used. Example script (SQL):

```
INSERT INTO solr_index (name, description) VALUES ('core_name1', 'Solr Search Index/Core');
[...]
```

Note: `solr_index.name` (in this case `core_name1`) will be used as the name of the Solr core, when performing a Core Reload (see `smui2solr.sh`).

#### Initial Solr Fields

Optional. Example script (SQL):

```
INSERT INTO suggested_solr_field (name, solr_index_id) values ('microline1', 1);
[...]
```

Refresh Browser window and you should be ready to go.

#### Convert existing rules.txt

Optional. The following RegEx search and replace pattern can be helpful (example search & replace regexes with Atom.io):

Input terms:
```
From: (.*?) =>
To  : INSERT INTO search_input (term, solr_index_id) VALUES ('$1', 1);\nSET @last_id_si = LAST_INSERT_ID();
```

Synonyms (directed-only assumed):
```
From: ^[ \t].*?SYNONYM: (.*)
To  : INSERT INTO synonym_rule (synonym_type, term, search_input_id) VALUES (1, '$1', @last_id_si);
```

UP/DOWN:
```
From: ^[ \t].*?UP\((\d*)\): (.*)
To  : INSERT INTO up_down_rule (up_down_type, boost_malus_value, term, search_input_id) VALUES (0, $1, '$2', @last_id_si);

From: ^[ \t].*?DOWN\((\d*)\): (.*)
To  : INSERT INTO up_down_rule (up_down_type, boost_malus_value, term, search_input_id) VALUES (1, $1, '$2', @last_id_si);
```

FILTER:
```
tbd
```

DELETE:
```
tbd
```

Replace comments:
```
From: #
To  : --
```

Hint: Other querqy compatible rules not editable with SMUI (e.g. DECORATE) must be removed to have a proper converted SQL script ready.

## MAINTENANCE

## Log data

The Log file(s) by default is/are located under the following path:

```
/var/log/search-management-ui/
```

Server log can be watched by example script (command line):

```
tail -f /var/log/search-management-ui/search-management-ui.log
```

### Add a new Solr Collection (SQL level)

See "Step 4". Example script (SQL):

```
INSERT INTO solr_index (name, description) VALUES ('added_core_name2', 'Added Index/Core Description #2');
INSERT INTO solr_index (name, description) VALUES ('added_core_name3', 'Added Index/Core Description #3');
[...]
```

### Add new Solr Fields (SQL level)

See "Step 4". Example script (SQL):

```
INSERT INTO suggested_solr_field (name, solr_index_id) values ('added_solr_field2', 1);
INSERT INTO suggested_solr_field (name, solr_index_id) values ('added_solr_field3', 1);
[...]
```

## DEVELOPMENT SETUP

For developing new features and test the application with different type of configuration, it is recommended to create a local development configuration of the application (instead of the productive one described above). There is the `smui-dev.conf` being excluded from version control through the `.gitignore`, so that you can safely create a local development configuration in the project's root (naming it `smui-dev.conf`). Here is an example being used on a local development machine adjusting some features:

```
include "application.conf"

db.default.url="jdbc:mysql://localhost/smui?autoReconnect=true&useSSL=false"
db.default.username="local_dev_db_user"
db.default.password="local_dev_db_pass"

smui2solr.SRC_TMP_FILE="/PATH/TO/LOCAL_DEV/TMP/FILE.tmp"
smui2solr.DST_CP_FILE_TO="PATH/TO/LOCAL_DEV/SOLR/CORE/CONF/rules.txt"
smui2solr.SOLR_HOST="localhost:8983"

toggle.ui-concept.updown-rules.combined=true
toggle.ui-concept.all-rules.with-solr-fields=true
toggle.rule-deployment.auto-decorate.export-hash=true
toggle.rule-deployment.split-decompound-rules-txt=true
toggle.rule-deployment.split-decompound-rules-txt-DST_CP_FILE_TO="/PATH/TO/LOCAL_DEV/SOLR/CORE/CONF/decompound-rules.txt"
toggle.rule-deployment.pre-live.present=true
toggle.rule-deployment.custom-script=true
toggle.rule-deployment.custom-script-SMUI2SOLR-SH_PATH="/PATH/TO/LOCAL_DEV/smui2solr-dev.sh"

play.http.secret.key="<generated local play secret>"

# smui.authAction = controllers.auth.BasicAuthAuthenticatedAction
# smui.BasicAuthAuthenticatedAction.user = smui_dev_user
# smui.BasicAuthAuthenticatedAction.pass = smui_dev_pass
```

As you can see, for development purposes you are recommended to have a local Solr installation running as well.

For running The SMUI application locally on your development machine pass the above config file when starting the application in `sbt`, e.g.:

```
run -Dconfig.file=./smui-dev.conf 9000
```

Furthermore, above's configuration points to a deviant development version of the `smui2solr.sh`-script. The file `smui2solr-dev.sh` is as well excluded from the version control. The following example provides a simple custom deployment script approach, that basically just delegates the script call to the main `smui2solr.sh` one:

```
echo "In smui2solr-dev.sh - DEV wrapper for smui2solr.sh, proving custom scripts work"

BASEDIR=$(dirname "$0")
$BASEDIR/conf/smui2solr.sh "$@"
exit $?
```

It can be used as a basis for extension.

Hint: Remember to give it a `+x` permission for being executable to the application.

### Docker Compose Based Development environment

This approach uses Docker Compose to manage the MySQL, Solr, and Play application:  

```
docker-compose -f build/developer-environment/docker-compose.yml up
```

Then, to launch the front end run:

```
sbt run -Dconfig.file=./build/developer-environment/smui-dev.conf 9000
```

The first time the SQL tables are created, so after the app starts, you need to manually create your Solr Index
entry in SMUI and then refresh the page at http://localhost:9000:

```
INSERT INTO solr_index (id, name, description) VALUES (1, 'core_name1', 'Solr Search Index/Core');
```

### Developing Custom Authentication

#### Authentication Backend

If you want to extend SMUI's authentication behaviour, you can do so by supplying your own authentication implementation into the classpath of SMUI's play application instance and referencing it in the `application.conf`. Your custom authentication action offers a maximum of flexibility as it is based upon play's `ActionBuilderImpl`. In addition your custom action gets the current environment's `appConfig`, so it can use configurations defined there as well. Comply with the following protocol:

```
import play.api.Configuration
import play.api.mvc._
import scala.concurrent.ExecutionContext
class myOwnAuthenticatedAction(parser: BodyParsers.Default,
                               appConfig: Configuration)(implicit ec: ExecutionContext) extends ActionBuilderImpl(parser) {
override def invokeBlock[A](request: Request[A], block: (Request[A]) => Future[Result]) = {
	...
}
```

As an example implementation, you can check `app/controllers/auth/BasicAuthAuthenticatedAction.scala` as well.

#### Frontend Behaviour for Authentication

The Angular frontend comes with a built-in HTTP request authentication interceptor. Every API request is observed for returned 401 status codes. In case the backend returns 401, the backend can pass an behaviour instruction to the frontend by complying with spec defined by `SmuiAuthViolation` within `app/assets/app/http-auth-interceptor.ts`, e.g.:

```
{
  "action": "redirect",
  "params": "https://www.example.com/loginService/?urlCallback={{CURRENT_SMUI_URL}}"
}
```

NOTE: The authentication interceptor only joins the game, in case the Angular application is successfully bootstrap'ed. So for SMUI's `/` route, your custom authentication method might choose a different behaviour (e.g. 302).

Within exemplary `redirect` action above, you can work with the `{{CURRENT_SMUI_URL}}` placeholder, that SMUI will replace with its current location as an absolute URL before the redirect gets executed. Through this, it becomes possible for the remote login service to redirect back to SMUI once the login has succeeded.

## License
Search Management UI (SMUI) is licensed under the [Apache License, Version 2](http://www.apache.org/licenses/LICENSE-2.0.html).

### Contributors

 - [Paul M. Bartusch](https://github.com/pbartusch), Committer/Maintainer
 - [Michael Gottschalk](https://github.com/migo)
