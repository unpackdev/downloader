// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./Ownable.sol";
import "./ERC20.sol";

contract Brain is ERC20, Ownable {
    mapping(address => bool) public controllers;

    constructor() ERC20("BRAIN", "BRAIN") {}

    function mint(address to, uint256 amount) external {
        require(controllers[msg.sender], "BRAIN: Only controller can mint!");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(controllers[msg.sender], "BRAIN: Only controller can burn!");
        _burn(from, amount);
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
}
