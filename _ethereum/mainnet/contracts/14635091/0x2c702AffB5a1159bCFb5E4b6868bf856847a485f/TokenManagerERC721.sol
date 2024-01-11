// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./EnumerableSet.sol";
import "./ERC721Holder.sol";
import "./IERC721.sol";
import "./ITokenManager.sol";
import "./TokenManagerMarketplace.sol";

contract TokenManagerERC721 is ERC721Holder, ITokenManager, TokenManagerMarketplace {
    function deposit(
        address from,
        address tokenAddress,
        uint256 tokenId,
        uint256
    ) external onlyAllowedMarketplaces returns (uint256) {
        IERC721(tokenAddress).safeTransferFrom(from, address(this), tokenId);
        return uint256(0);
    }

    function withdraw(
        address to,
        address tokenAddress,
        uint256 tokenId,
        uint256
    ) external onlyAllowedMarketplaces returns (uint256) {
        IERC721(tokenAddress).safeTransferFrom(address(this), to, tokenId);
        return uint256(0);
    }
}