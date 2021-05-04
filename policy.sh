#!/usr/bin/env bash

export ASSET_NAME="laufentaler20"
export DESCRIPTION="a POC coin for the 42 region CH"
export TICKER="LT20"
export URL="https://laufentaler.ch"
export ICON="../laufentaler.png"

cd cardano

export CARDANO_NODE_SOCKET_PATH=socket
 
./cardano-node run --topology configuration/cardano/mainnet-topology.json --database-path db --config configuration/cardano/mainnet-config.json --port 3001 --socket-path "$CARDANO_NODE_SOCKET
_PATH"

export NETWORK_ID="--testnet-magic 764824073"

echo "Building payment keys..."
./cardano-cli address key-gen --verification-key-file pay.vkey --signing-key-file pay.skey

echo "Building payment address..."
./cardano-cli address build $NETWORK_ID --payment-verification-key-file pay.vkey --out-file pay.addr

export PAYMENT_ADDR=$(cat pay.addr)
echo "Payment address is: $PAYMENT_ADDR"

mkdir policy

echo "Generating policy keys..."
./cardano-cli address key-gen --verification-key-file policy/policy.vkey --signing-key-file policy/policy.skey

export KEYHASH=$(./cardano-cli address key-hash --payment-verification-key-file policy/policy.vkey)

echo "Creating policy script..."
export SCRIPT=policy/policy.script
echo "{" >> $SCRIPT
echo "  \"keyHash\": \"${KEYHASH}\"," >> $SCRIPT
echo "  \"type\": \"sig\"" >> $SCRIPT
echo "}" >> $SCRIPT

cat $SCRIPT

export POLICY_ID=$(./cardano-cli transaction policyid --script-file $SCRIPT)

echo "AssetID is: $POLICY_ID.$ASSET_NAME"