// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract Template {

    using SafeERC20 for IERC20;

    function withdrawToken(address _token, address _target) external returns (uint amount) {
        IERC20 token = IERC20(_token);
        amount = token.balanceOf(address(this));
        token.safeTransfer(_target, amount);
    }

}