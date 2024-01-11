// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./AccessControl.sol";

contract SmeshToken is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint public _totalSupply;

    constructor() ERC20("Smesh Coin", "SMESH") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _totalSupply = 36000000000000000000000000;
        
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(totalSupply() <= _totalSupply, "Maximum Supply Reached");
        require(amount <= _totalSupply, "Mint Amount Above Maximum Supply");

        _mint(to, amount);
    }
}

