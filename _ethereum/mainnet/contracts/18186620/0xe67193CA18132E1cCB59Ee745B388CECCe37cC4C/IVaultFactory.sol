// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IDepositHandler.sol";

interface IVaultFactory is IDepositHandler {
    function createVault(
        address referrer,
        address beneficiary,
        uint256 unlockTimestamp,
        IDepositHandler.FungibleTokenDeposit[] memory fungibleTokenDeposits,
        IDepositHandler.NonFungibleTokenDeposit[] memory nonFungibleTokenDeposits,
        IDepositHandler.MultiTokenDeposit[] memory multiTokenDeposits,
        bool isVesting
    ) external payable;

    function createVaultWithoutKey(
        address referrer,
        address beneficiary,
        uint256 unlockTimestamp,
        IDepositHandler.FungibleTokenDeposit[] memory fungibleTokenDeposits,
        IDepositHandler.NonFungibleTokenDeposit[] memory nonFungibleTokenDeposits,
        IDepositHandler.MultiTokenDeposit[] memory multiTokenDeposits,
        bool isVesting
    ) external payable;

    function burn(
        address referrer,
        IDepositHandler.FungibleTokenDeposit[] memory fungibleTokenDeposits,
        IDepositHandler.NonFungibleTokenDeposit[] memory nonFungibleTokenDeposits,
        IDepositHandler.MultiTokenDeposit[] memory multiTokenDeposits
    ) external payable;

    function notifyUnlock(bool isCompletelyUnlocked) external;

    function lockExtended(uint256 oldUnlockTimestamp, uint256 newUnlockTimestamp) external;

    function paymentModule() external view returns (address);
}
