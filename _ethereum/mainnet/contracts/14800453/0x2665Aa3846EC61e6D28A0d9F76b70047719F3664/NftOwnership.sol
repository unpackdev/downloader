//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./IERC1155Upgradeable.sol";
import "./IERC721Upgradeable.sol";

interface IPunk {
    function punkIndexToAddress(uint256 index) external view returns (address);
}

/// @dev This is a library for other contracts to use that need to verify ownership of an NFT on the current chain.
/// Since this only has internal functions, it will be inlined into the calling contract at
/// compile time and does not need to be separately deployed on chain.
library NftOwnership {
    /// @dev For the specified NFT, verify it is owned by the potential owner
    function _verifyOwnership(
        address nftContractAddress,
        uint256 nftId,
        address potentialOwner
    ) internal view returns (bool) {
        // Try ERC1155
        try
            IERC1155Upgradeable(nftContractAddress).balanceOf(
                potentialOwner,
                nftId
            )
        returns (uint256 balance) {
            return balance > 0;
        } catch {
            // Ignore error
        }

        // Try ERC721
        try IERC721Upgradeable(nftContractAddress).ownerOf(nftId) returns (
            address foundOwner
        ) {
            return foundOwner == potentialOwner;
        } catch {
            // Ignore error
        }

        // Try CryptoPunk
        try IPunk(nftContractAddress).punkIndexToAddress(nftId) returns (
            address foundOwner
        ) {
            return foundOwner == potentialOwner;
        } catch {
            // Ignore error
        }

        return false;
    }
}
