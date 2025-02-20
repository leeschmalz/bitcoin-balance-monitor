#!/bin/bash

echo "=== Balance check for $(date) ==="

LAST_BLOCK_FILE="last_scanned_block.txt"
bitcoin-cli loadwallet "btc" 2>/dev/null || true
printf "\n"

# Read last scanned block if file exists, otherwise start 100000 blocks back
if [ -f "$LAST_BLOCK_FILE" ]; then
    START_HEIGHT=$(cat "$LAST_BLOCK_FILE")
else
    CURRENT_HEIGHT=$(bitcoin-cli getblockchaininfo | grep '"blocks"' | awk '{print $2}' | tr -d ',')
    START_HEIGHT=$((CURRENT_HEIGHT - 100000))
    [ $START_HEIGHT -lt 0 ] && START_HEIGHT=0
fi

printf "\033[30;1mRe-scanning from block %s...\033[0m\n" "$START_HEIGHT"
bitcoin-cli -rpcclienttimeout=3000 -rpcwallet=btc rescanblockchain $START_HEIGHT
printf "\n"

# Save current block height for next run
bitcoin-cli getblockchaininfo | grep '"blocks"' | awk '{print $2}' | tr -d ',' > "$LAST_BLOCK_FILE"

# Show balances
printf "\033[30;1mAddress Balances:\033[0m\n"
bitcoin-cli -rpcwallet=btc listunspent | jq 'group_by(.address) | map({address: .[0].address, total: map(.amount) | add})'
printf "\n"
printf "\033[30;1mTotal Balance:\033[0m\n"
bitcoin-cli -rpcwallet=btc listunspent | jq '[.[] | select(.address != "bc1qk7fy6qumtdkjy765ujxqxe0my55ake0zefa2dmt6sjx2sr098d8qf26ufn") | .amount] | add'
printf "\n"
