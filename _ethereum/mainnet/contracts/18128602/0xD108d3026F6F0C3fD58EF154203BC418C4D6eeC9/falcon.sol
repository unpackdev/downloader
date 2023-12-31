// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./ERC20.sol";
import "./ERC20Permit.sol";
import "./ERC20Votes.sol";
import "./Ownable.sol";

// File: FalconHu.sol
// @title FLCHU: An erc20 token with erc20 permit
// using oz erc20, erc20 permit and ownable
contract FLCHU is  ERC20, ERC20Permit, ERC20Votes, Ownable {
    uint256 maxSupply = 21e6 * 1e5; // 21 million token (5 decimals)
    constructor () ERC20 ("Falcon Hu", "FLCHU") ERC20Permit ("Falcon HU") {
     _mint(msg.sender, maxSupply);
    }

    // The following functions are overrides required by Solidity.

    function decimals () public pure  override (ERC20) returns (uint8) {
        return 5;
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}

