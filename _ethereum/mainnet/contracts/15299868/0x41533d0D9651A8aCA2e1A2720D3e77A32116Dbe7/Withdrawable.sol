// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControlEnumerable.sol";

abstract contract Withdrawable {
    using SafeERC20 for IERC20;

    modifier protectedWithdrawal() virtual;

    receive() external payable {}

    function withdrawToken(address to, address token_) external protectedWithdrawal {
        IERC20 tokenToWithdraw = IERC20(token_);
        tokenToWithdraw.safeTransfer(to, tokenToWithdraw.balanceOf(address(this)));
    }

    function withdrawETH(address payable to) external protectedWithdrawal {
        to.transfer(address(this).balance);
    }
}
