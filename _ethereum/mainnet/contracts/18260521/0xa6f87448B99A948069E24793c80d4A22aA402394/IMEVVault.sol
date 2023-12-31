// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IVaultManager.sol";

interface IMEVVault {

    function vaultManager() external view returns(IVaultManager);

    function lastFee() external view returns(uint256);

    function extractMEV() external;

    function updateFee() external;
}
