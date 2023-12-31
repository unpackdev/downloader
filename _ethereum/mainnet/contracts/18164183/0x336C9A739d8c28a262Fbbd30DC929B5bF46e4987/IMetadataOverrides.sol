// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

interface IMetadataOverrides {
    function metadataOverrides(uint hash) external view returns (string memory);

    function overrideMetadata(uint256 hash, string memory uri, string memory reason) external;

    function deleteMetadataOverride(uint256 hash) external;
    
    function overrideMetadataBulk(uint256[] memory hashes, string[] memory uris, string[] memory reasons) external;
}
