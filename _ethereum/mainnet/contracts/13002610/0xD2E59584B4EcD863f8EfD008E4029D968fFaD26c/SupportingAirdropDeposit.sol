// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface SupportingAirdropDeposit {
    function depositTokens(uint256 liquidityDeposit, uint256 redistributionDeposit, uint256 buybackDeposit) external;
    function burn(uint256 amount) external;
}
