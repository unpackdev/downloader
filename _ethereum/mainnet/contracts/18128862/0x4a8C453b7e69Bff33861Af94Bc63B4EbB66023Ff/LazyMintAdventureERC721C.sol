// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LazyMintAdventureERC721.sol";
import "./CreatorTokenBase.sol";

abstract contract LazyMintAdventureERC721C is 
    LazyMintAdventureERC721, 
    CreatorTokenBase {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ICreatorToken).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @dev Ties the adventure erc721 _beforeTokenTransfer hook to more granular transfer validation logic
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize) internal virtual override {
        LazyMintAdventureERC721._beforeTokenTransfer(from, to, firstTokenId, batchSize); 

        if(transferType == TRANSFERRING_VIA_ERC721) {
            for (uint256 i = 0; i < batchSize;) {
                _validateBeforeTransfer(from, to, firstTokenId + i);
    
                unchecked {
                    ++i;
                }
            }
        }
    }

    /// @dev Ties the adventure erc721 _afterTokenTransfer hook to more granular transfer validation logic
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize) internal virtual override {
        for (uint256 i = 0; i < batchSize;) {
            _validateAfterTransfer(from, to, firstTokenId + i);
            unchecked {
                ++i;
            }
        }
    }
}

abstract contract LazyMintAdventureERC721CInitializable is 
    LazyMintAdventureERC721Initializable, 
    CreatorTokenBase {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ICreatorToken).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @dev Ties the adventure erc721 _beforeTokenTransfer hook to more granular transfer validation logic
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize) internal virtual override {
        LazyMintAdventureERC721Initializable._beforeTokenTransfer(from, to, firstTokenId, batchSize); 

        if(transferType == TRANSFERRING_VIA_ERC721) {
            for (uint256 i = 0; i < batchSize;) {
                _validateBeforeTransfer(from, to, firstTokenId + i);
    
                unchecked {
                    ++i;
                }
            }
        }
    }

    /// @dev Ties the adventure erc721 _afterTokenTransfer hook to more granular transfer validation logic
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize) internal virtual override {
        for (uint256 i = 0; i < batchSize;) {
            _validateAfterTransfer(from, to, firstTokenId + i);
            unchecked {
                ++i;
            }
        }
    }
}