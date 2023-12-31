// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./LazyMintAdventureERC721C.sol";

import "./OwnableInitializable.sol";
import "./MetadataURI.sol";

abstract contract LazyMintAdventureERC721CMetadataInitializable is 
    OwnableInitializable, 
    MetadataURIInitializable, 
    LazyMintAdventureERC721CInitializable {
    using Strings for uint256;

    /// @notice Returns tokenURI if baseURI is set
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if(!_exists(tokenId)) {
            revert LazyMintERC721Base__TokenDoesNotExist();
        }

        string memory baseURI = baseTokenURI;
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), suffixURI))
            : "";
    }
}