// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract SharedLogic {
    // Percents are represented as integers. Samples: 10000 == 100%, 2500 == 25%, 450 = 4.5%, 75 = 0.75%, 5 = 0.05%
    uint256 internal constant PERCENTAGE = 10000;

    address public _config;
}
