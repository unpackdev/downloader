// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./SafeERC20.sol";
import "./IERC721.sol";
import "./Address.sol";

abstract contract Releasable {
    using Address for address;

    event ReleasedETH(address to, uint256 amount);
    event ReleasedERC20(IERC20 indexed token, address to, uint256 amount);
    event ReleasedERC721(IERC721 indexed token, address to, uint256 tokenId);

    receive() external payable virtual {}

    function _releaseAllETH(address payable account) internal virtual {
        uint256 amount = address(this).balance;
        _releaseETH(account, amount);
    }

    function _releaseETH(
        address payable account,
        uint256 amount
    ) internal virtual {
        uint256 totalBalance = address(this).balance;
        require(totalBalance != 0, "Releasable: no network tokens to release");
        require(
            totalBalance >= amount,
            "Releasable: not enough network tokens to release"
        );
        Address.sendValue(account, amount);
        emit ReleasedETH(account, amount);
    }

    function _releaseAllERC20(IERC20 token, address account) internal virtual {
        uint256 amount = token.balanceOf(address(this));
        _releaseERC20(token, account, amount);
    }

    function _releaseERC20(
        IERC20 token,
        address account,
        uint256 amount
    ) internal virtual {
        uint256 totalBalance = token.balanceOf(address(this));
        require(totalBalance != 0, "Releasable: no ERC20 tokens to release");
        require(
            totalBalance >= amount,
            "Releasable: not enough ERC20 tokens to release"
        );
        SafeERC20.safeTransfer(token, account, amount);
        emit ReleasedERC20(token, account, amount);
    }
}
