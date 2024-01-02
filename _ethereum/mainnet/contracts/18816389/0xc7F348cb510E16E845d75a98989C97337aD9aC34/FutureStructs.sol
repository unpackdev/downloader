// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

struct FuturesUser {
    uint deposits; //total inbound deposits
    uint compound_deposits; //compound deposit; not fresh capital
    uint current_balance; //current balance
    uint payouts; //total yield payouts across all farms
    uint rewards; //partner rewards
    uint last_time; //last interaction
}
