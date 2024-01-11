// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ITransferManagerNFT.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./Ownable.sol";

contract TransferManagerERC1155 is Ownable, ITransferManagerNFT, ERC1155Holder {
    address public MNFTMarketplace;

    function setMarketPlace(address marketplaceAddress_) external onlyOwner {
        MNFTMarketplace = marketplaceAddress_;
    }

    function transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external override {
        require(msg.sender == MNFTMarketplace, "Transfer: Only MNFT Marketplace");
        IERC1155 token = IERC1155(collection);
        token.safeTransferFrom(from, address(this), tokenId, amount, "");
        token.safeTransferFrom(address(this), to, tokenId, amount, "");
    }
}
