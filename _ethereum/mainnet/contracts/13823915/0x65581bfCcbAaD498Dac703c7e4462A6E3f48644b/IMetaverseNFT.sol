// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMetaverseNFT {
    function isExtensionAllowed(address extension) external view returns (bool);
    function tokenData(uint256 tokenId) external view returns (bytes32);

    function mintExternal(uint256 nTokens, address to, bytes32 data) external payable;
    function addExtension(address extension) external;
    function revokeExtension(address extension) external;
}
