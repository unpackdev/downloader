// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20BurnableUpgradeable.sol";
import "./Gang.sol";

contract Gang2 is Gang, ERC20BurnableUpgradeable {
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override (ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }
    function _mint(address to, uint256 amount) internal virtual override (ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._mint(to, amount);
    }
    function _burn(address from, uint256 amount) internal virtual override (ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._burn(from, amount);
    }
}