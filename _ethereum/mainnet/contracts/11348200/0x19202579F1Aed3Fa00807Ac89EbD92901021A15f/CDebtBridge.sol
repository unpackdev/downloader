// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

function GAS_COSTS_FOR_FULL_REFINANCE() pure returns (uint256[4] memory) {
    return [uint256(2000000), 2400000, 2850000, 3500000];
}

uint256 constant PREMIUM = 20;
uint256 constant VAULT_CREATION_COST = 150000;
