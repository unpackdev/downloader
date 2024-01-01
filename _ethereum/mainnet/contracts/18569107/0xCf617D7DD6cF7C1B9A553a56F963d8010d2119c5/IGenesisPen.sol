// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IGenesisPen {
    function authorizedMint(address addr_, uint256 amount_) external;

    /// View
    function getRemainingBalance(address addr_) external view returns (uint256);
}