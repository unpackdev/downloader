// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract MMMM6900 is ERC20 {
    constructor() ERC20("MetaMaskMichaelMyersMurderMemes6900", "MMMM6900") {
        _mint(msg.sender, 69000000 * 10 ** 18); // Mint 69,000,000 tokens and assign them to the contract deployer
    }
    function buyTokens(uint256 amount) public payable {
        require(msg.value >= amount, "Insufficient funds sent");
        _transfer(address(this), msg.sender, amount);
    }

    function sellTokens(uint256 amount) public {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _transfer(msg.sender, address(this), amount);
    }

    // The standard ERC-20 functions
    function transfer(address to, uint256 amount) public override returns (bool) {
        require(to != address(0), "Transfer to the zero address");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // The constructor sets the initial supply and assigns it to the specified holder.
    // The contract has no owner and cant be changed
    // No minting whitelisting blacklisting or burning functions are included.
    // Power back to the people. Kill the memes. Myers coming for you.
   

}
