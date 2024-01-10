// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IOnchainVaults {
    function depositERC20ToVault(
        uint256 assetId,
        uint256 vaultId,
        uint256 quantizedAmount
    ) external;

    function depositEthToVault(
        uint256 assetId, 
        uint256 vaultId) 
    external payable;

    function withdrawFromVault(
        uint256 assetId,
        uint256 vaultId,
        uint256 quantizedAmount
    ) external;

    function getQuantizedVaultBalance(
        address ethKey,
        uint256 assetId,
        uint256 vaultId
    ) external view returns (uint256);

    function getVaultBalance(
        address ethKey,
        uint256 assetId,
        uint256 vaultId
    ) external view returns (uint256);

    function getQuantum(uint256 presumedAssetType) external view returns (uint256);

    function orderRegistryAddress() external view returns (address);

    function isAssetRegistered(uint256 assetType) external view returns (bool);

    function getAssetInfo(uint256 assetType) external view returns (bytes memory assetInfo);
}