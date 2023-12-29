// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./AccessControl.sol";

/**
 * @dev Definitive Reward Token
 * Bookkeeping token for DefinitiveStrategyManager. Only the strategy
 * manager itself can mint and burn tokens.
 */
contract DefinitiveRewardToken is ERC20, AccessControl {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(
        address to,
        uint256 amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(to, amount);
    }

    function burn(
        address from,
        uint256 amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _burn(from, amount);
    }
}
