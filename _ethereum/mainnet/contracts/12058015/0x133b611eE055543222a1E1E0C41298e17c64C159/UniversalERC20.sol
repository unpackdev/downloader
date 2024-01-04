// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

library UniversalERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function universalTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        token.safeTransferFrom(from, to, amount);
    }

    function universalTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        universalTransfer(token, to, amount, false);
    }

    function universalTransfer(
        IERC20 token,
        address to,
        uint256 amount,
        bool mayFail
    ) internal returns(bool) {
        if (amount == 0) {
            return true;
        }

        token.safeTransfer(to, amount);
        return true;
    }
}
