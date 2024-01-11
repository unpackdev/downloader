// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "ExtendedCollectionMH.sol";

contract SingleTokenMH is ExtendedCollectionMH {
    event PermanentURI(string _value, uint256 indexed _id); // Freezing Metadata for OpenSea

    constructor(string memory name_, string memory symbol_,
                string memory contractURI_, string memory tokenURI_,
                address receiver_) ExtendedCollectionMH(name_, symbol_, contractURI_, tokenURI_, 1, receiver_) { }

    function tokenURI() public view returns (string memory) {
        return _baseURI();
    }

    function ownerOf() public view returns (address) {
        return ownerOf(1);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId == 1, "ERC721Metadata: URI query for nonexistent token");
        return _baseURI();
    }

    // Lock metadata forever
    function lockURI() external override onlyOwner {
        isLockedURI = true;
        emit PermanentURI(tokenURI(), 1);
    }
}
