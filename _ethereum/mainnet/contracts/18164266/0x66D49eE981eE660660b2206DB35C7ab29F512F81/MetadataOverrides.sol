// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./Ownable.sol";

contract MetadataOverrides is Ownable {
    mapping(uint256 => string) public metadataOverrides;
    address public metadataContract;

    event MetadataOverridden(uint256 indexed tokenHash, string newUri, string reason);
    event MetadataOverrideDeleted(uint256 indexed tokenHash);

    constructor(address _metadataContract) {
        metadataContract = _metadataContract;
    }

    function overrideMetadata(uint256 hash, string memory uri, string memory reason) external {
        require(msg.sender == metadataContract, "Only metadata contract can override metadata");
        metadataOverrides[hash] = uri;
        emit MetadataOverridden(hash, uri, reason);
    }

    function overrideMetadataBulk(uint256[] memory hashes, string[] memory uris, string[] memory reasons) external {
        require(msg.sender == metadataContract, "Only metadata contract can override metadata");
        require(hashes.length == uris.length && hashes.length == reasons.length, "Arrays are different lengths");
        for (uint256 i = 0; i < hashes.length; i++) {
            metadataOverrides[hashes[i]] = uris[i];
            emit MetadataOverridden(hashes[i], uris[i], reasons[i]);
        }
    }

    function deleteMetadataOverride(uint256 hash) external {
        require(msg.sender == metadataContract, "Only metadata contract can override metadata");
        if (bytes(metadataOverrides[hash]).length != 0) {
            delete metadataOverrides[hash];
            emit MetadataOverrideDeleted(hash);
        }
    }

    function setMetadataContract(address _metadataContract) external onlyOwner {
        metadataContract = _metadataContract;
    }
}
