// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";
import "./ERC20Votes.sol";
import "./ERC20FlashMint.sol";
import "./Ownable.sol";

/// @custom:security-contact info@tripscommunity.com
contract TRIPS is ERC20, ERC20Burnable, ERC20Permit, ERC20Votes, ERC20FlashMint, Ownable {
    constructor(address initialOwner)
        ERC20("TRIPS", "TRIPS")
        ERC20Permit("TRIPS")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 63000000 * 10 ** decimals());
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}
