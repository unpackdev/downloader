// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC1155.sol";
import "./ITokenManager.sol";
import "./ERC1155Holder.sol";
import "./TokenManagerMarketplace.sol";

contract TokenManagerERC1155 is ERC1155Holder, ITokenManager, TokenManagerMarketplace {
    function deposit(
        address from,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount
    ) external onlyAllowedMarketplaces returns (uint256) {
        require(amount > 0, "DroppingNowMarketplace: auction with zero or less amount for ERC1155 cannot be created"); 

        IERC1155(tokenAddress).safeTransferFrom(from, address(this), tokenId, amount, "");
        return amount;
    }

    function withdraw(
        address to,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount
    ) external onlyAllowedMarketplaces returns (uint256) {
        IERC1155(tokenAddress).safeTransferFrom(address(this), to, tokenId, amount, "");
        return amount;
    }
}