// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.21;

interface ILRTConfig {
    // Errors
    error ValueAlreadyInUse();
    error AssetAlreadySupported();
    error AssetNotSupported();
    error CallerNotLRTConfigAdmin();
    error CallerNotLRTConfigManager();
    error CallerNotLRTConfigAllowedRole(string role);

    // Events
    event SetToken(bytes32 key, address indexed tokenAddr);
    event SetContract(bytes32 key, address indexed contractAddr);
    event AddedNewSupportedAsset(address indexed asset, uint256 depositLimit);
    event RemovedSupportedAsset(address indexed asset);
    event AssetDepositLimitUpdate(address indexed asset, uint256 depositLimit);
    event AssetStrategyUpdate(address indexed asset, address indexed strategy);
    event SetRSETH(address indexed rsETH);

    // methods

    function rsETH() external view returns (address);

    function assetStrategy(address asset) external view returns (address);

    function isSupportedAsset(address asset) external view returns (bool);

    function getLSTToken(bytes32 tokenId) external view returns (address);

    function getContract(bytes32 contractId) external view returns (address);

    function getSupportedAssetList() external view returns (address[] memory);

    function depositLimitByAsset(address asset) external view returns (uint256);
}
