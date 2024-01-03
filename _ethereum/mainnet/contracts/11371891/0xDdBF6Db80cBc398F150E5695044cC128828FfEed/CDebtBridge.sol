// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

function GAS_COSTS_FOR_FULL_REFINANCE() pure returns (uint256[4] memory) {
    return [uint256(2519000), 3140500, 3971000, 4345000];
}

uint256 constant PREMIUM = 30;
uint256 constant VAULT_CREATION_COST = 200000;
