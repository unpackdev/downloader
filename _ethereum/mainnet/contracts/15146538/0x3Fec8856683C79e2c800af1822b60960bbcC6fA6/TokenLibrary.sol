// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

library TokenLibrary {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function isEth(IERC20 token) internal pure returns(bool) {
        return address(token) == address(0) || address(token) == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    }

    function universalBalanceOf(IERC20 token, address account) internal view returns (uint256) {
        if (isEth(token)) {
            return account.balance;
        } else {
            return token.balanceOf(account);
        }
    }

    function universalTransfer(IERC20 token, address payable to, uint256 amount) internal {
        if (isEth(token)) {
            to.transfer(amount);
        } else {
            token.safeTransfer(to, amount);
        }
    }
}
