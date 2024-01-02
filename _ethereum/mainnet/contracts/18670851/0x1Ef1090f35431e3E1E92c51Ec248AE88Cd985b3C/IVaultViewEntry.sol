// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./Structs.sol";

interface IVaultViewEntry {
    function getOraclePriceOverride(
        address vaultAddress,
        uint40 timestamp
    ) external view returns (uint128);

    function getVault(
        address vaultAddress
    ) external view returns (Vault memory);

    function getVaultProductId(address vault) external view returns (uint32);

    function getIsDefaulted(address vaultAddress) external view returns (bool);

    function getDaysLate(address vaultAddress) external view returns (uint256);

    function totalAssets(address vaultAddress) external view returns (uint256);

    function convertToAssets(
        address vaultAddress,
        uint256 shares
    ) external view returns (uint128);

    function convertToShares(
        address vaultAddress,
        uint128 assets
    ) external view returns (uint256);
}
