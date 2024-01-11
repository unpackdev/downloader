// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ITransferManagerNFT.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./Ownable.sol";
import "./console.sol";

contract TransferManagerERC721 is ERC721Holder, Ownable, ITransferManagerNFT {
    address private MNFTMarketplace;

    function setMarketPlace(address marketplaceAddress_) external onlyOwner {
        MNFTMarketplace = marketplaceAddress_;
    }

    function transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) external override {
        require(msg.sender == MNFTMarketplace, "Transfer: Only MNFT Marketplace");

        IERC721 token = IERC721(collection);
        require (
            token.getApproved(tokenId) == address(this) ||
            token.isApprovedForAll(from, address(this)), 
            'not approved'
        );
        token.safeTransferFrom(from, address(this), tokenId);
        token.safeTransferFrom(address(this), to, tokenId);
    }
}
