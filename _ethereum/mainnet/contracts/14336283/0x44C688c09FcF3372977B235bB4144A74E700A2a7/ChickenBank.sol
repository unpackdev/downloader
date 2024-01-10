pragma solidity ^0.8.0;

import "./EGGS.sol";
import "./AccessControlEnumerable.sol";

contract ChickenBank is AccessControlEnumerable {

    EGGS public EGGS_TOKEN = EGGS(0x2c91885519718Ff0d6D52C323d38C9Fc44F88321);

    uint256 public sellPrice = 2600;
    uint256 public buyPrice = 2000; 
    bool public open = true; 
    
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
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
        require((open), "Admin has disabled transactions.");
        EGGS_TOKEN.transferFrom(msg.sender, address(this), amount);
        uint256 ethPayout = amount / sellPrice;
        address payable seller = payable(msg.sender);
        seller.transfer(ethPayout);
    }

    function buy() 
    public payable
    {
        require((open), "Admin has disabled transactions.");
        uint256 purchase = msg.value * buyPrice;
        EGGS_TOKEN.transfer(msg.sender, purchase);
    }

    function changePrices(uint256 _buyPrice, uint256 _sellPrice) 
    public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "You don't have permission to do this.");
        require(_sellPrice > _buyPrice, "Sell price must always be higher than buy price.");
        buyPrice = _buyPrice;
        sellPrice = _sellPrice;
    }

    function setOpen(bool _isOpen) 
    public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "You don't have permission to do this.");
        open = _isOpen;
    }
}