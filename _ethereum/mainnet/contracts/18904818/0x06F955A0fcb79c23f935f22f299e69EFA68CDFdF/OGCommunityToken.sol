// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Permit.sol";
import "./ERC20Votes.sol";
import "./ERC20Capped.sol";


contract OGCommunityToken is ERC20, Ownable, ERC20Permit, ERC20Votes, ERC20Capped {
    constructor(address initialOwner)
        ERC20("OGCommunity", "OGC")
        Ownable(initialOwner)
        ERC20Permit("OGCommunity")
        ERC20Capped(1000000000 * 10 ** decimals())
    {
        _mint(initialOwner, 100000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes, ERC20Capped)
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
