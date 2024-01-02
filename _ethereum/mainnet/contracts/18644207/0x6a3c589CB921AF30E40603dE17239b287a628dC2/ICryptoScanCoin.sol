// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.20;

import "./IERC20.sol";

interface ICryptoScanCoin is IERC20 {
    function startSale(address saleContract) external;
    function sendOutSuccessTokens(uint256 phase, uint256 numberOfPresalePhases, uint256 successRate) external returns (bool);
}
