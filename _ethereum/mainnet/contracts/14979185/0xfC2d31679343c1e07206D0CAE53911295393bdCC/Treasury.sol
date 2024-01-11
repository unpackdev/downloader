// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract Treasury {
    using SafeERC20 for IERC20;

    function _takeMoneyFromSender(
        IERC20 currency,
        address sender,
        uint256 amount
    ) internal {
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = currency.allowance(sender, address(this));
        require(allowance >= amount, "Check the token allowance");

        currency.safeTransferFrom(address(sender), address(this), amount);
    }

    function _sendMoneyToIDOOwner(
        IERC20 currency,
        address to,
        uint256 amount
    ) internal {
        currency.safeTransfer(to, amount);
    }
}
