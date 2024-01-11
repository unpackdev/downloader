// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./LibTokenDividendPool.sol";

contract TokenDividendPoolStorage {

    bool public pauseProxy;
    bool public migratedL2;

    address public erc20DividendAddress;
    mapping(address => LibTokenDividendPool.Distribution) public distributions;
    address[] public distributedTokens;
    uint256 internal free = 1;
}
