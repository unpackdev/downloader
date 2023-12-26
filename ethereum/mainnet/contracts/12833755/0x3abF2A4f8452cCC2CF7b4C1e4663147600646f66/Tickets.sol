// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC20.sol";
import "./draft-ERC20Permit.sol";
import "./Erc20Permit.sol";

import "./ITickets.sol";

import "./Ownable.sol";

contract Tickets is ERC20, ERC20Permit, Ownable, ITickets {
    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
        ERC20Permit(_name)
    {}

    function print(address _account, uint256 _amount)
        external
        override
        onlyOwner
    {
        return _mint(_account, _amount);
    }

    function redeem(address _account, uint256 _amount)
        external
        override
        onlyOwner
    {
        return _burn(_account, _amount);
    }
}
