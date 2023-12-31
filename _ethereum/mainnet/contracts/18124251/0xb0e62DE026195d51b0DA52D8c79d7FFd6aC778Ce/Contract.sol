// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";

contract SecureTokenHolder {
    function transferERC20(
        address tokenAddress,
        address from,
        address to,
        uint256 amount
    ) external {
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(from, to, amount);
    }

    function transferERC721(
        address tokenAddress,
        address from,
        address to,
        uint256 tokenId
    ) external {
        IERC721 token = IERC721(tokenAddress);
        token.safeTransferFrom(from, to, tokenId);
    }
}