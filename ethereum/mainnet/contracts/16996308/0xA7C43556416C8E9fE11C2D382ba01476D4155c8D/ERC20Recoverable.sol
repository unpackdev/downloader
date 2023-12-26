// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

abstract contract ERC20Recoverable is Context {
    using SafeERC20 for IERC20;

    event Recovered(address token, address account, uint256 amount);

    function _recoverERC20(address tokenAddress) internal {
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenAmount = token.balanceOf(address(this));
        require(tokenAmount > 0, "ERC20Recoverable: no token to recover");
        token.safeTransfer(_msgSender(), tokenAmount);
        emit Recovered(tokenAddress, _msgSender(), tokenAmount);
    }
}
