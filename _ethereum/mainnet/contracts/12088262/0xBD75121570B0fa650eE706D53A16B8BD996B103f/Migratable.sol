// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "./IERC20.sol";
import "./MigratableOwnership.sol";

contract Migratable is MigratableOwnership {
    /// Migrate balances of a set of tokens
    /// @param tokens a set of tokens to transfer balances to target
    /// @param target new owner of contract balances
    function migrateBalances(address[] memory tokens, address target)
        public
        onlyOwner
        nonReentrant
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            uint256 balance = token.balanceOf(address(this));
            if (balance > 0) {
                token.transfer(target, balance);
                emit MigratedBalance(
                    msg.sender,
                    address(token),
                    target,
                    balance
                );
            }
        }
    }

    event MigratedBalance(
        address indexed owner,
        address indexed token,
        address target,
        uint256 value
    );
}
