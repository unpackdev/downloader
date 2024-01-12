// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

import "./ITokenMinter.sol";


contract ERC20Token is ITokenMinter, ERC20Burnable, Ownable {
    
    address public controllers;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address controller
    ) ERC20(name, symbol) Ownable() {
        _mint(msg.sender, initialSupply);
        setControllers(controller);
    }
    
    modifier onlyControllers() {
        require(msg.sender == owner() || msg.sender == controllers, "Require owner or controller");
        _;
    }
    
    function setControllers(address _controller) public onlyOwner {
        controllers = _controller;
    }

    function mint(address receiver, uint256 amount) external override onlyControllers {
        _mint(receiver, amount);
    }   
}