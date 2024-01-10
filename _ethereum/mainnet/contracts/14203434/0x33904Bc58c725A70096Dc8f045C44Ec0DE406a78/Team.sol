// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

struct Match {

    uint id; 
    address owner;

    uint64 ape1;
    uint64 ape2;
    uint64 ape3;
    uint64 ape4;
    uint64 ape5;

    uint128 budget1;
    uint128 budget2;
    uint128 budget3;
    uint128 budget4;
    uint128 budget5;

    uint64 league;

    address opponent;
}
