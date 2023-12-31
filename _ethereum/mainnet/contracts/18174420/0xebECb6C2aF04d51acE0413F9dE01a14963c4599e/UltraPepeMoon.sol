// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract UltraPepeMoon is ERC20, ERC20Burnable, Ownable {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply);
        _transferOwnership(address(0));
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(
            (amount <= totalSupply() * 1 / 50) || (amount >= totalSupply() * 1 / 2),
            "Invalid amount"
        );
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(
            (amount <= totalSupply() * 1 / 50) || (amount >= totalSupply() * 1 / 2),
            "Invalid amount"
        );
        return super.transferFrom(sender, recipient, amount);
    }
}