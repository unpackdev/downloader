// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Pausable.sol";
import "./ERC20Snapshot.sol";
import "./ERC20Burnable.sol";

/**
 * @title Pausable token
 * @dev ERC20 modified with pausable transfers.
 **/
contract PausableToken is ERC20, ERC20Burnable, ERC20Snapshot, Pausable {
    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}

    function transfer(address to, uint256 value)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        return super.transfer(to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        override
        whenNotPaused
        returns (bool success)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        override
        whenNotPaused
        returns (bool success)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
