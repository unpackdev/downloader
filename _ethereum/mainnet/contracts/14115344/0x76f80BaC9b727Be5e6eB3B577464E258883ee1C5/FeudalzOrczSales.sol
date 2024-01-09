// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./Ownable.sol";
import "./IGoldz.sol";

interface IFeudalzOrcz {
    function mint(uint quantity, address receiver) external;
}

contract FeudalzOrczSales is Ownable {
    IGoldz goldz = IGoldz(0x7bE647634A942e73F8492d15Ae492D867Ce5245c);
    IFeudalzOrcz orcz = IFeudalzOrcz(0x60A0860503D9ECDA03436cA692D948319f5377f7);
    
    bool public isSalesActive = true;
    uint public price;
    
    constructor() {
        price = 40 ether;
    }

    function mint(uint quantity) external {
        require(isSalesActive, "sale is not active");
        
        goldz.transferFrom(msg.sender, address(this), price * quantity);
        
        orcz.mint(quantity, msg.sender);
    }
    
    function toggleSales() external onlyOwner {
        isSalesActive = !isSalesActive;
    }
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }

    function burnGoldz() external onlyOwner {
        uint balance = goldz.balanceOf(address(this));
        goldz.burn(balance);
    }

    function withdrawGoldz() external onlyOwner {
        uint amount = goldz.balanceOf(address(this));
        goldz.transfer(msg.sender, amount);
    }
}