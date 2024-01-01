// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

contract VeydarToken is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 8000000000 * 10**18; // 8 billion tokens with 18 decimals

    constructor() ERC20("Veydar", "VEYDAR") {
        // Mint initial supply to the contract deployer
        _mint(msg.sender, 8000000000 * 10**18); // 8,000,000,000 VEYDAR with 18 decimals
    }

    // Function to mint new tokens, can only be called by the owner
    function mint(address account, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds maximum supply");
        _mint(account, amount);
    }

    // Function to burn tokens, can only be called by the owner
    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
    }

    // Function to transfer ownership to a new address, can only be called by the owner
    function transferOwnership(address newOwner) public onlyOwner override {
        _transferOwnership(newOwner);
    }
}