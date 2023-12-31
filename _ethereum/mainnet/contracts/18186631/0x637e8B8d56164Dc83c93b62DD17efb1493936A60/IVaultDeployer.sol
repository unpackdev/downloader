// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IDepositHandler.sol";

interface IVaultDeployer is IDepositHandler {
    function createVestingVault(
        bool shouldMintKey,
        address beneficiary,
        uint256 unlockTimestamp,
        bytes memory fungibleTokenDeposits
    ) external returns (address);

    function createBatchVault(
        bool shouldMintKey,
        address beneficiary,
        uint256 unlockTimestamp,
        bytes memory fungibleTokenDeposits,
        bytes memory nonFungibleTokenDeposits,
        bytes memory multiTokenDeposits
    ) external returns (address);
}
