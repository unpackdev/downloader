// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title IPFactory
 * @author pNetwork
 *
 * @notice
 */
interface IPFactory {
    event PTokenDeployed(address pTokenAddress);

    function deploy(
        string memory underlyingAssetName,
        string memory underlyingAssetSymbol,
        uint256 underlyingAssetDecimals,
        address underlyingAssetTokenAddress,
        bytes4 underlyingAssetNetworkId
    ) external payable returns (address);

    function getBytecode(
        string memory underlyingAssetName,
        string memory underlyingAssetSymbol,
        uint256 underlyingAssetDecimals,
        address underlyingAssetTokenAddress,
        bytes4 underlyingAssetNetworkId
    ) external view returns (bytes memory);

    function getPTokenAddress(
        string memory underlyingAssetName,
        string memory underlyingAssetSymbol,
        uint256 underlyingAssetDecimals,
        address underlyingAssetTokenAddress,
        bytes4 underlyingAssetNetworkId
    ) external view returns (address);

    function setHub(address _hub) external;
}
