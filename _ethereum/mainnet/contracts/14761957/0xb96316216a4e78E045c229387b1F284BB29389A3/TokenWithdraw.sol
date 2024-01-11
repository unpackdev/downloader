// SPDX-License-Identifier: MIT
// Creator: tyler@radiocaca.com

pragma solidity ^0.8.8;

import "./SafeERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

abstract contract TokenWithdraw is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    function withdraw(address payable to, uint256 amount) external onlyOwner nonReentrant {
        Address.sendValue(to, amount);
    }

    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner nonReentrant {
        IERC20(token).safeTransfer(to, amount);
    }

    function withdrawERC721(
        address token,
        address to,
        uint256 tokenId
    ) external onlyOwner nonReentrant {
        IERC721(token).safeTransferFrom(address(this), to, tokenId);
    }
}
