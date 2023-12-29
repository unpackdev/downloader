// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./Strings.sol";
import "./Ownable.sol";
import "./Lockable.sol";

import "./IMetadataResolver.sol";

// @author: NFT Studios - Buildtree

contract MultiTokenMetadataBaseUrl is Ownable, IMetadataResolver {
    using Strings for uint256;

    mapping(address => string) public baseURI;

    function setBaseURI(address _contract, string memory _baseURI) external {
        require(msg.sender == Ownable(_contract).owner(), "caller can not set a new baseURI");
        require(Lockable(_contract).isMetadataLocked() == false, "metadata for this contract is locked");

        baseURI[_contract] = _baseURI;
    }

    function getTokenURI(uint256 _tokenId) external view returns (string memory) {
        return string(abi.encodePacked(baseURI[msg.sender], _tokenId.toString()));
    }
}
