// contracts/MCNCoin.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";

contract MCNCoin is ERC20, ERC20Permit, ERC20Votes {
    constructor(uint256 initialSupply, address treasury)
        ERC20("MCNCoin", "MCN")
        ERC20Permit("Metaverse Commerce Network")
    {
        _mint(treasury, initialSupply);
    }

    // The following functions are overrides required by Solidity.
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}
