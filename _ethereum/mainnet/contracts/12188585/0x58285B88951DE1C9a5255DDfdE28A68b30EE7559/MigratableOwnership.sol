// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Operatable.sol";

contract MigratableOwnership is Ownable, ReentrancyGuard {
    /// Migrate ownership and operator of a set of tokens
    /// @param tokens a set of tokens to transfer ownership and operator to target
    /// @param target new owner and operator of the token
    function migrateOwnership(address[] memory tokens, address target)
        public
        onlyOwner
        nonReentrant
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            Operatable token = Operatable(tokens[i]);
            if (token.owner() == address(this)) {
                token.transferOperator(target);
                token.transferOwnership(target);
                emit MigratedOwnership(msg.sender, address(token), target);
            }
        }
    }

    event MigratedOwnership(
        address indexed owner,
        address indexed token,
        address target
    );
}
