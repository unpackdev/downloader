//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SafeTokenHolder
 * @author gotbit
 */

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

interface ISafeERC20Holder {
    event WithdrawToken(
        uint256 indexed timestamp,
        address indexed user,
        address token,
        uint256 amount
    );
}

contract SafeERC20Holder is ISafeERC20Holder {
    using SafeERC20 for IERC20;

    /// @dev withdraws specific `token_` from contract (if amount greater than balance withdraws all balance)
    /// @param token_ address of token
    /// @param amount uint id which be minted
    function _withdraw(IERC20 token_, uint256 amount) internal {
        if (token_.balanceOf(address(this)) < amount)
            amount = token_.balanceOf(address(this));
        token_.safeTransfer(msg.sender, amount);

        emit WithdrawToken(block.timestamp, msg.sender, address(token_), amount);
    }
}
