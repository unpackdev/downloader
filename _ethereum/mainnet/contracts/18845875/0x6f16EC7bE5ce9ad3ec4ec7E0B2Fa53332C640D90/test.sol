// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Permit.sol";

contract PervToken is ERC20, Ownable, ERC20Permit {
    address private deployer;
    uint256 private taxRate; // Tax rate in percentage

    constructor(address initialOwner)
        ERC20("PervToken", "PERV")
        Ownable(initialOwner)
        ERC20Permit("PervToken")
    {
        deployer = initialOwner;
        _mint(msg.sender, 7000000000000 * 10 ** decimals());
        taxRate = 2; // Default tax rate set to 2%
    }

    function setTaxRate(uint256 newTaxRate) public onlyOwner {
        require(newTaxRate <= 20, "Tax rate must be between 0% and 20%");
        taxRate = newTaxRate;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        uint256 taxAmount = (amount * taxRate) / 100;
        uint256 newAmount = amount - taxAmount;
        
        super._transfer(sender, deployer, taxAmount);
        super._transfer(sender, recipient, newAmount);
    }
}
