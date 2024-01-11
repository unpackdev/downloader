// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./ERC20.sol";

contract ELO is ERC20, Ownable {
    mapping(address => bool) public controllers;

    constructor() ERC20("ELO", "ELO") {}

    function mint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Access: Only controller can mint!");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(controllers[msg.sender], "Access: Only controller can burn!");
        _burn(from, amount);
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
}
