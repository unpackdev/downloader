// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface INFTDeployer {
    function deploy(uint256 collectionId, string memory name, string memory symbol) external returns (address proxy);

    function computeProxyAddress(
        uint256 collectionId,
        string memory name,
        string memory symbol
    ) external view returns (address);

    function computeImplementationAddress(
        uint256 collectionId,
        string memory name,
        string memory symbol
    ) external view returns (address);
}
