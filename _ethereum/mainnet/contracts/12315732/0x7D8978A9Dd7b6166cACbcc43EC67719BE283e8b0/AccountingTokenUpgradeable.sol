// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Upgradeable.sol";

/**
 * @dev This contract is version of ERC20 token, but with limitations: holder can't transfer these tokens.
 */
contract AccountingTokenUpgradeable is ERC20Upgradeable {
    function __AccountingToken_init(string memory name_, string memory symbol_)
        internal
        initializer
    {
        __ERC20_init(name_, symbol_);

        __AccountingToken_init_unchained();
    }

    function __AccountingToken_init_unchained() internal initializer {}

    // Do not need transfer of this token
    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        revert("Forbidden");
    }

    // Do not need allowance of this token
    function _approve(
        address,
        address,
        uint256
    ) internal pure override {
        revert("Forbidden");
    }
}
