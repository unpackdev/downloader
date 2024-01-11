// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract MROWToken is ERC20, ERC20Burnable, Ownable {
    mapping(address => bool) controllers;

    constructor() ERC20("MROWToken", "MROW") {}

    function mint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        _mint(to, amount);
    }

    function mintGroup(address[] calldata adds, uint256 qty) external {
        require(controllers[msg.sender], "Only controllers can mint");
        for (uint256 i = 0; i < adds.length; i++) {
            _mint(adds[i], qty);
        }
    }

    function burnFrom(address account, uint256 amount) public override {
        require(controllers[msg.sender], "Only controllers can burn");
        _burn(account, amount);
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
}
