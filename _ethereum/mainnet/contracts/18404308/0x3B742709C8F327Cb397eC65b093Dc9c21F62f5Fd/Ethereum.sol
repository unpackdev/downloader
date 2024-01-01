// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./Ownable.sol";
import "./ERC20Permit.sol";

contract Ethereum is ERC20, ERC20Burnable, ERC20Pausable, Ownable, ERC20Permit {
    constructor(address initialOwner)
        ERC20("ethereum", "ETH")
        Ownable(initialOwner)
        ERC20Permit("ethereum")
    {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
    {
        super._update(from, to, value);
    }
}
