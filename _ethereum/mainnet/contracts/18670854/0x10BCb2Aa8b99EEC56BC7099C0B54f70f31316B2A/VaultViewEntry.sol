// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./IVaultViewEntry.sol";
import "./Structs.sol";
import "./CegaStorage.sol";
import "./Errors.sol";
import "./VaultLogic.sol";

contract VaultViewEntry is IVaultViewEntry, CegaStorage {
    // MODIFIERS

    modifier onlyValidVault(address vaultAddress) {
        CegaGlobalStorage storage cgs = getStorage();
        require(cgs.vaults[vaultAddress].productId != 0, Errors.INVALID_VAULT);
        _;
    }

    // VIEW FUNCTIONS

    function getOraclePriceOverride(
        address vaultAddress,
        uint40 timestamp
    ) external view returns (uint128) {
        CegaGlobalStorage storage cgs = getStorage();

        return cgs.oraclePriceOverride[vaultAddress][timestamp];
    }

    function getVault(
        address vaultAddress
    ) external view onlyValidVault(vaultAddress) returns (Vault memory) {
        CegaGlobalStorage storage cgs = getStorage();
        return cgs.vaults[vaultAddress];
    }

    function getVaultProductId(address vault) external view returns (uint32) {
        CegaGlobalStorage storage cgs = getStorage();

        return cgs.vaults[vault].productId;
    }

    function getIsDefaulted(
        address vaultAddress
    ) external view onlyValidVault(vaultAddress) returns (bool) {
        CegaGlobalStorage storage cgs = getStorage();
        return VaultLogic.getIsDefaulted(cgs, vaultAddress);
    }

    function getDaysLate(
        address vaultAddress
    ) external view onlyValidVault(vaultAddress) returns (uint256) {
        CegaGlobalStorage storage cgs = getStorage();
        return VaultLogic.getDaysLate(cgs.vaults[vaultAddress].tradeStartDate);
    }

    function totalAssets(address vaultAddress) external view returns (uint256) {
        CegaGlobalStorage storage cgs = getStorage();
        return VaultLogic.totalAssets(cgs, vaultAddress);
    }

    function convertToAssets(
        address vaultAddress,
        uint256 shares
    ) external view returns (uint128) {
        CegaGlobalStorage storage cgs = getStorage();
        return VaultLogic.convertToAssets(cgs, vaultAddress, shares);
    }

    function convertToShares(
        address vaultAddress,
        uint128 assets
    ) external view returns (uint256) {
        CegaGlobalStorage storage cgs = getStorage();
        return VaultLogic.convertToShares(cgs, vaultAddress, assets);
    }
}
