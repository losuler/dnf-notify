<div align="center">
<p align="center">
  <p align="center">
    <h3 align="center">DNF Notify</h3>
    <p align="center">
      Notify about new updates in <code>dnf</code>.
    </p>
  </p>
</p>
</div>

## About

A simple bash script to overcome the limitations in notifications in `dnf-automatic`. In the past I had used a hack on the `[command_email]` section in `automatic.conf` to send notifications via Telegram with the following:

```sh
command_format = "curl --silent --output /dev/null --data-urlencode 'chat_id={{ chat_id }}' --data @- 'https://api.telegram.org/bot{{ bot_token }}/sendMessage'"
```

However due to the desire to use Matrix and have a different output than just what updates had been automatically installed, along with the added complexity that come with escaping this for `json`, I wrote this simple script to do this for me.

## Usage

```
Usage: dnf-notify [OPTION]...
Check for and notify of new updates available.
  -c PATH       Path to the config file
  -h            Print help and exit
```

## Configuration

Enable the service you would like to recieve notifications on (e.g. Matrix):

```sh
# Enable/Disable (Default: Disable)
MATRIX="enable"
```

### Matrix

`MATRIX_DOMAIN`

This is the domain for the Matrix server your room is hosted on. For most people this will likely be `matrix.org`.

`MATRIX_ROOM`

This is the internal room ID. The syntax is `!` followed by a random set of letters, for example `!abCDEfGhiJKLMnopQRs`. In Element you can find this by going to the room ➝ `Settings` ➝ `Advanced`.

`MATRIX_TOKEN`

This is the access token or secret that is used to authenticate the sending of the messages. You may retrieve this by either logging into Element through the browser or running the following command and copying the value from `access_token`:

```sh
curl -XPOST -d '{"type":"m.login.password", "user":"$USERNAME", "password":"$PASSWORD"}' \
    "https://matrix.org/_matrix/client/r0/login"
```
