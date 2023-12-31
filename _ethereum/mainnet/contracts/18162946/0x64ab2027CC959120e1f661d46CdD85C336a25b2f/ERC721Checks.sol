// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./IERC721.sol";
import "./Errors.sol";

library ERC721Checks {
  function sellerMustBeOwner(
    IERC721 nftContract,
    uint256 tokenId,
    address seller
  ) internal view {
    address owner = nftContract.ownerOf(tokenId);
    if (owner != seller) {
      revert NFTMarketBuyNow__SellingAgreement__NotTokenOwner();
    }
  }

  function marketplaceMustBeApproved(
    IERC721 nftContract,
    address seller
  ) internal view {
    bool approved = nftContract.isApprovedForAll(seller, address(this));
    if (!approved) {
      revert NFTMarketBuyNow__MarketplaceNotApproved();
    }
  }
}
