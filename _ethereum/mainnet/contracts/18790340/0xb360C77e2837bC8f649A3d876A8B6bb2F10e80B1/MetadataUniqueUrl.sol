// SPDX-License-Identifier: MIT
// @author: NFT Studios

pragma solidity ^0.8.18;

import "./Ownable.sol";

import "./IMetadataResolver.sol";

contract MetadataUniqueUrl is Ownable, IMetadataResolver {
    string public uri;

    function setURI(string memory _uri) external onlyOwner {
        uri = _uri;
    }

    function getTokenURI(uint256) external view returns (string memory) {
        return uri;
    }
}
