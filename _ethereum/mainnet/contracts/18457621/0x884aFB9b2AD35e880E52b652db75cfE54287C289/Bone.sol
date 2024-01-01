// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract Bone is ERC20, ERC20Burnable, Ownable {

    mapping(address => bool) public controllers;

    constructor() ERC20("Bone", "BONE") {
        controllers[msg.sender] = true;
    }

    function mint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        _mint(to, amount);
    }

    function burnFrom(address account, uint256 amount) public override {
        if (controllers[msg.sender]) {
            _burn(account, amount);
        } else {
            super.burnFrom(account, amount);
        }
    }

    /* Staking Contract has to be added as a Controller in Order to award Tokens for Staking */

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

}