// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./SafeERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC721Upgradeable.sol";


contract TokensRecoverable is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function recoverTokens(IERC20Upgradeable token) public onlyOwner {
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function recoverBNB(uint256 amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function recoverERC721(IERC721Upgradeable token, uint256 tokenId) public onlyOwner {
        token.safeTransferFrom(address(this), msg.sender, tokenId);
    }
}
