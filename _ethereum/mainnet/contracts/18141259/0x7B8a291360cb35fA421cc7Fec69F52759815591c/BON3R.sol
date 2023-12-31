// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";
import "ERC20Permit.sol";
import "ERC20Votes.sol";

contract BON3R is ERC20Permit, ERC20Votes {
    constructor() ERC20("BON3R", "BONR") ERC20Permit("BON3R") {
        _mint(msg.sender, 1000000000000e18 );
    }

    // The functions below are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}