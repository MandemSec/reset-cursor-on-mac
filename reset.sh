#!/bin/bash

# =========================================================
#  Reset Cursor on Mac
#  Author: @siina42069 (Twitter) | @mandemsec (GitHub)
#  Date: Sun Mar 16 17:04:20 UTC 2025
# =========================================================

if [ -n "$SUDO_USER" ]; then
    CURRENT_USER="$SUDO_USER"
elif [ -n "$DOAS_USER" ]; then
    CURRENT_USER="$DOAS_USER"
else
    CURRENT_USER=$(who am i | awk '{print $1}')
    if [ -z "$CURRENT_USER" ]; then
        CURRENT_USER=$(logname)
    fi
fi

if [ -z "$CURRENT_USER" ]; then
    echo "Error: Unable to determine actual user"
    exit 1
fi

USER_HOME=$(eval echo ~$CURRENT_USER)

for cmd in uuidgen ioreg; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is required but not found"
        exit 1
    fi
done

generate_mac_id() {
    uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
    uuid=$(echo $uuid | sed 's/.\{12\}\(.\)/4/')
    random_hex=$(echo $RANDOM | md5 | cut -c1)
    random_num=$((16#$random_hex))
    new_char=$(printf '%x' $(( ($random_num & 0x3) | 0x8 )))
    uuid=$(echo $uuid | sed "s/.\{16\}\(.\)/$new_char/")
    echo $uuid
}

generate_unique_id() {
    uuid1=$(uuidgen | tr -d '-')
    uuid2=$(uuidgen | tr -d '-')
    echo "${uuid1}${uuid2}"
}

if pgrep -x "Cursor" > /dev/null || pgrep -f "Cursor.app" > /dev/null; then
    echo "Cursor is running. Please close Cursor before continuing..."
    echo "Waiting for Cursor process to exit..."
    while pgrep -x "Cursor" > /dev/null || pgrep -f "Cursor.app" > /dev/null; do
        sleep 1
    done
fi

echo "Cursor has been closed, continuing execution..."

STORAGE_PATH="$USER_HOME/Library/Application Support/Cursor/User/globalStorage/storage.json"
APP_FILES=(
    "/Applications/Cursor.app/Contents/Resources/app/out/main.js"
    "/Applications/Cursor.app/Contents/Resources/app/out/vs/code/node/cliProcessMain.js"
)

restore_backup() {
    if [ -f "${STORAGE_PATH}.bak" ]; then
        cp "${STORAGE_PATH}.bak" "$STORAGE_PATH" && {
            echo "Restored storage.json"
            chown $CURRENT_USER:staff "$STORAGE_PATH"
            chmod 644 "$STORAGE_PATH"
        } || echo "Error: Failed to restore storage.json"
    else
        echo "Warning: Backup file for storage.json does not exist"
    fi

    if [ -d "/Applications/Cursor.backup.app" ]; then
        echo "Restoring Cursor.app..."
        osascript -e 'tell application "Cursor" to quit' || true
        sleep 2
        
        rm -rf "/Applications/Cursor.app"
        mv "/Applications/Cursor.backup.app" "/Applications/Cursor.app" && {
            echo "Restored Cursor.app"
        } || echo "Error: Failed to restore Cursor.app"
    else
        echo "Warning: Backup for Cursor.app does not exist"
    fi

    echo "Restore operation completed"
    exit 0
}

if [ "$1" = "--restore" ]; then
    restore_backup
fi

NEW_ID=$(generate_unique_id)
NEW_MAC_ID=$(generate_mac_id)
NEW_DEVICE_ID=$(uuidgen)
NEW_SQM="{$(uuidgen | tr '[:lower:]' '[:upper:]')}"

if [ -f "$STORAGE_PATH" ]; then
    cp "$STORAGE_PATH" "${STORAGE_PATH}.bak" || {
        echo "Error: Unable to backup storage.json"
        exit 1
    }
    
    chown $CURRENT_USER:staff "${STORAGE_PATH}.bak"
    chmod 644 "${STORAGE_PATH}.bak"
    
    osascript -l JavaScript << EOF
        function run() {
            const fs = $.NSFileManager.defaultManager;
            const path = '$STORAGE_PATH';
            const nsdata = fs.contentsAtPath(path);
            const nsstr = $.NSString.alloc.initWithDataEncoding(nsdata, $.NSUTF8StringEncoding);
            const content = nsstr.js;
            const data = JSON.parse(content);
            
            data['telemetry.machineId'] = '$NEW_ID';
            data['telemetry.macMachineId'] = '$NEW_MAC_ID';
            data['telemetry.devDeviceId'] = '$NEW_DEVICE_ID';
            data['telemetry.sqmId'] = '$NEW_SQM';
            
            const newContent = JSON.stringify(data, null, 2);
            const newData = $.NSString.alloc.initWithUTF8String(newContent);
            newData.writeToFileAtomicallyEncodingError(path, true, $.NSUTF8StringEncoding, null);
            
            return "success";
        }
EOF
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to update storage.json"
        exit 1
    fi

    chown $CURRENT_USER:staff "$STORAGE_PATH"
    chmod 644 "$STORAGE_PATH"
fi

echo "Successfully updated all IDs:"
echo "Backup file created at: ${STORAGE_PATH}.bak"
echo "New telemetry.machineId: $NEW_ID"
echo "New telemetry.macMachineId: $NEW_MAC_ID"
echo "New telemetry.devDeviceId: $NEW_DEVICE_ID"
echo "New telemetry.sqmId: $NEW_SQM"
echo ""

echo "Copying Cursor.app to temporary directory..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TMP_DIR="/tmp/cursor_reset_${TIMESTAMP}"
TMP_APP="$TMP_DIR/Cursor.app"

if [ -d "$TMP_DIR" ]; then
    echo "Cleaning existing temporary directory..."
    rm -rf "$TMP_DIR"
fi

mkdir -p "$TMP_DIR" || {
    echo "Error: Unable to create temporary directory"
    exit 1
}

cp -R "/Applications/Cursor.app" "$TMP_DIR" || {
    echo "Error: Unable to copy app to temporary directory"
    rm -rf "$TMP_DIR"
    exit 1
}

chown -R $CURRENT_USER:staff "$TMP_DIR"
chmod -R 755 "$TMP_DIR"

echo "Removing temporary app signature..."
codesign --remove-signature "$TMP_APP" || {
    echo "Warning: Failed to remove app signature"
}

HELPERS=(
    "$TMP_APP/Contents/Frameworks/Cursor Helper.app"
    "$TMP_APP/Contents/Frameworks/Cursor Helper (GPU).app"
    "$TMP_APP/Contents/Frameworks/Cursor Helper (Plugin).app"
    "$TMP_APP/Contents/Frameworks/Cursor Helper (Renderer).app"
)

for helper in "${HELPERS[@]}"; do
    if [ -e "$helper" ]; then
        echo "Removing signature: $helper"
        codesign --remove-signature "$helper" || {
            echo "Warning: Failed to remove component signature: $helper"
        }
    fi
done

APP_FILES=(
    "$TMP_APP/Contents/Resources/app/out/main.js"
    "$TMP_APP/Contents/Resources/app/out/vs/code/node/cliProcessMain.js"
)

for file in "${APP_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Warning: File $file does not exist"
        continue
    fi

    backup_file="${file}.bak"
    cp "$file" "$backup_file" || {
        echo "Error: Unable to backup file $file"
        continue
    }

    content=$(cat "$file")
    
    uuid_pos=$(printf "%s" "$content" | grep -b -o "IOPlatformUUID" | cut -d: -f1)
    if [ -z "$uuid_pos" ]; then
        echo "Warning: IOPlatformUUID not found in $file"
        continue
    fi

    before_uuid=${content:0:$uuid_pos}
    switch_pos=$(printf "%s" "$before_uuid" | grep -b -o "switch" | tail -n1 | cut -d: -f1)
    if [ -z "$switch_pos" ]; then
        echo "Warning: switch keyword not found in $file"
        continue
    fi

    printf "%sreturn crypto.randomUUID();\n%s" "${content:0:$switch_pos}" "${content:$switch_pos}" > "$file" || {
        echo "Error: Unable to write to file $file"
        continue
    }

    echo "Successfully modified file: $file"
done

echo "Re-signing temporary app..."
codesign --sign - "$TMP_APP" --force --deep || {
    echo "Warning: Re-signing failed"
}

echo "Closing Cursor..."
osascript -e 'tell application "Cursor" to quit' || true
sleep 2

echo "Backing up original app..."
if [ -d "/Applications/Cursor.backup.app" ]; then
    rm -rf "/Applications/Cursor.backup.app"
fi
mv "/Applications/Cursor.app" "/Applications/Cursor.backup.app" || {
    echo "Error: Unable to backup original app"
    rm -rf "$TMP_DIR"
    exit 1
}

echo "Installing modified app..."
mv "$TMP_APP" "/Applications/" || {
    echo "Error: Unable to install modified app"
    mv "/Applications/Cursor.backup.app" "/Applications/Cursor.app"
    rm -rf "$TMP_DIR"
    exit 1
}

rm -rf "$TMP_DIR"

echo "Application modifications complete! Original app has been backed up as /Applications/Cursor.backup.app"
echo "All operations completed"
