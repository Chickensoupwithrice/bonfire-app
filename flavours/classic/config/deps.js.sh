#!/bin/sh

# any extensions/deps with a package.json in their /assets directory
# space seperated
DEPS='bonfire_editor_ck'

chmod +x ./priv/deps.js.sh
./priv/deps.js.sh "$DEPS"