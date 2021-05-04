NAME="laufentaler"
DESCRIPTION="a POC coin for the 42 region CH"
TICKER="LT"
URL="https://laufentaler.ch"
ICON="laufentaler.png"
USERNAME="soerenOsisa"

sudo apt install cabal-install

mkdir cardano && cd cardano

wget https://hydra.iohk.io/build/5266641/download/1/cardano-node-1.24.2-linux.tar.gz
tar xzvf cardano-node-1.24.2-linux.tar.gz
mkdir lpconfig && cd lpconfig
wget https://hydra.iohk.io/build/5102327/download/1/launchpad-config.json
wget https://hydra.iohk.io/build/5102327/download/1/launchpad-byron-genesis.json
wget https://hydra.iohk.io/build/5102327/download/1/launchpad-shelley-genesis.json
wget https://hydra.iohk.io/build/5102327/download/1/launchpad-topology.json
cd ..

./cardano-node run --topology ./lpconfig/launchpad-topology.json --database-path ./state-lp --port 3001
--config ./lpconfig/launchpad-config.json --socket-path ~/cardano-lp.socket
export CARDANO_NODE_SOCKET_PATH=~/cardano-lp.socket

mkdir policy

cardano-cli address key-gen \
    --verification-key-file policy/policy.vkey \
    --signing-key-file policy/policy.skey

touch policy/policy.script && echo "" > policy/policy.script

echo "{" >> policy/policy.script

echo "  \"keyHash\": \"$(./cardano-cli address key-hash --payment-verification-key-file policy/policy.vkey)\"," >> policy/policy.script

echo "  \"type\": \"sig\"" >> policy/policy.script 

echo "}" >> policy/policy.script 

POLICY=$(./cardano-cli transaction policyid --script-file ./policy/policy.script) 

mkdir token-creator

cd token-creator

git clone https://github.com/input-output-hk/offchain-metadata-tools .

curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

cd token-metadata-creator

ID=$POLICY+$(echo -n "$NAME" | xxd -ps)

cat > policy.json <<- EOM
{"type": "all","scripts": [{
	"keyHash": "$ID",
	"type": "sig"}]}
EOM

cabal update

cabal build :token-metadata-creator

cabal run :token-metadata-creator --init $ID

cabal run :token-metadata-creator entry $ID \
  --name "$NAME" \
  --description "$DESCRIPTION" \
  --policy policy.json \
  --ticker "$TICKER" \
  --url "$URL" \
  --logo "$ICON" 

cabal run :token-metadata-creator entry $ID -a policy.sk

cabal run :token-metadata-creator entry $ID --finalize

cabal run :token-metadata-creator validate $ID.json 

cd ../..

git clone git@github.com:$USERNAME/cardano-token-registry

cd cardano-token-registry

cp ./token-creator/token-metadata-creator/$ID.json mappings/

git add mappings/$ID.json

git commit -m "$NAME"

git push origin HEAD