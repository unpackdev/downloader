// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC20.sol";
import "./SafeERC20.sol";

abstract contract Salvageable {
    using SafeERC20 for IERC20;

    function _salvage(address[] memory tokens) internal {
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            require(canSalvage(token), "token not salvageable");
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                IERC20(token).safeTransfer(msg.sender, balance);
            }
        }
    }

    function canSalvage(address token) public pure virtual returns (bool);
}
