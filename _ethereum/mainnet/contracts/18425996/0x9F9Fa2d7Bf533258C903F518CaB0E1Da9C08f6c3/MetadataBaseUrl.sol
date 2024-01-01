// SPDX-License-Identifier: MIT
// @author: NFT Studios

pragma solidity ^0.8.18;

import "./Strings.sol";
import "./Ownable.sol";

import "./IMetadataResolver.sol";

contract MetadataBaseUrl is Ownable, IMetadataResolver {
    using Strings for uint256;

    string public baseURI;

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function getTokenURI(
        uint256 _tokenId
    ) external view returns (string memory) {
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }
}
