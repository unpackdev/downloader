// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

contract Storage  {
    uint256 public amountInCached;
    uint256 public feeRate;
    uint256 public feeDenominator;
    address public feeCollector;
    address public WETH;
    address public factoryV2;
    address public factoryV3;

    mapping (address => bool) public feeExcludeList;
}
