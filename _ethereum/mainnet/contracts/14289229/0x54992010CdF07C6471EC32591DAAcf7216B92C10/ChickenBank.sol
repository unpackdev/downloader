pragma solidity ^0.8.0;

import "./EGGS.sol";

contract ChickenBank {

    EGGS public EGGS_TOKEN = EGGS(0x1dD2b08E568Af98a9b4156B165AC0D3d73939782);

    uint256 public price = 2600; 
    
    constructor() {
    }

    receive() 
    external payable 
    {
    }

    function EGGSBalance() 
    public view returns (uint256)
    {
        return EGGS_TOKEN.balanceOf(address(this));
    }

    function ETHBalance() 
    public view returns (uint256)
    {
        return address(this).balance;
    }

    function sell(uint256 amount) 
    public payable
    {
        EGGS_TOKEN.transferFrom(msg.sender, address(this), amount);
        uint256 ethPayout = amount / price;
        address payable seller = payable(msg.sender);
        seller.transfer(ethPayout);
    }

    function buy() 
    public payable
    {
        uint256 purchase = msg.value * price;
        EGGS_TOKEN.approve(msg.sender, purchase);
        EGGS_TOKEN.transfer(msg.sender, purchase);
    }
}