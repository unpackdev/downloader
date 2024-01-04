// SPDX-License-Identifier: None
pragma solidity >=0.7.5;

import "./IERC20.sol";
import "./SafeERC20.sol";

/// @title LibERC20Token
/// @notice Utility function for ERC20 tokens
library LibERC20Token {
    using SafeERC20 for IERC20;

    /// @param token Token to approve
    /// @param spender Address of wallet to approve spending for
    /// @param amount Amount of token to approve
    function approveIfBelow(IERC20 token, address spender, uint256 amount) internal {
        uint256 currentAllowance = token.allowance(address(this), spender);

        if (currentAllowance < amount) {
            // we can optimise gas by using uint256(-1) instead of `amount`
            // using amount is safer, but then each time we interacting with token
            // we have to approve it.
            // For now, let's go with more secure option,
            // when we add whitelisting for tokens and revoke "super admin" option for updating modules
            // we can go for gas and change it to uint256.max
            //
            // however gas usage base on tests looks like this:
            // - with amount:       min 126003, max 442559, avg 249189
            // - with uint256(-1):  min 141006, max 499514, avg 277865
            // so we will spend more at first run (when we need to save all uint256 bits),
            // but then we will gain in next runs.
            token.safeIncreaseAllowance(spender, amount - currentAllowance);
        }
    }
}
