// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*

▄▄▄█████▓ ██░ ██ ▓█████     ██░ ██ ▓█████  ██▓  ██████ ▄▄▄█████▓
▓  ██▒ ▓▒▓██░ ██▒▓█   ▀    ▓██░ ██▒▓█   ▀ ▓██▒▒██    ▒ ▓  ██▒ ▓▒
▒ ▓██░ ▒░▒██▀▀██░▒███      ▒██▀▀██░▒███   ▒██▒░ ▓██▄   ▒ ▓██░ ▒░
░ ▓██▓ ░ ░▓█ ░██ ▒▓█  ▄    ░▓█ ░██ ▒▓█  ▄ ░██░  ▒   ██▒░ ▓██▓ ░ 
  ▒██▒ ░ ░▓█▒░██▓░▒████▒   ░▓█▒░██▓░▒████▒░██░▒██████▒▒  ▒██▒ ░ 
  ▒ ░░    ▒ ░░▒░▒░░ ▒░ ░    ▒ ░░▒░▒░░ ▒░ ░░▓  ▒ ▒▓▒ ▒ ░  ▒ ░░   
    ░     ▒ ░▒░ ░ ░ ░  ░    ▒ ░▒░ ░ ░ ░  ░ ▒ ░░ ░▒  ░ ░    ░    
  ░       ░  ░░ ░   ░       ░  ░░ ░   ░    ▒ ░░  ░  ░    ░      
          ░  ░  ░   ░  ░    ░  ░  ░   ░  ░ ░        ░           
                                                            
*/

import "./Ownable.sol";
import "./ECDSA.sol";

import "./PaymentsShared.sol";
import "./I_TokenBank.sol";

contract BuyBanksDutch is Ownable, PaymentsShared {

    using ECDSA for bytes32;

    uint256 public constant MAX_MINTABLE = 1250;
    uint256 public MINTS_PER_TRANSACTION = 5;
    bool public isSaleLive;

    I_TokenBank tokenBank;

    //events
    event SaleLive(bool onSale);

    //dutch
    uint256 startTimestamp;
    uint256 startPrice = 1 ether;
    uint256 endPrice = 0.2 ether;
    uint256 duration = 80 minutes; 
    uint256 initialPeriod = 30 minutes;

    uint256 discountRate = (startPrice - endPrice) / duration; //eth per second discount

    constructor(address _tokenBankAddress) {
        tokenBank = I_TokenBank(_tokenBankAddress);
    }

    function buy(uint8 amountToBuy) external payable {

        require(isSaleLive, "Sale is not live");
        require(msg.sender == tx.origin,"EOA only");

        //check price
        uint256 _ethPrice = getPrice();
        require(msg.value >= _ethPrice * amountToBuy,"Not enough ETH");        

        require(amountToBuy > 0, "Buy at least 1");
        require(amountToBuy < MINTS_PER_TRANSACTION + 1,"Over max per transaction");
        require(tokenBank.totalSupply() + amountToBuy < MAX_MINTABLE + 1,"Sold out");
    
        //Do minting
        tokenBank.Mint(amountToBuy, msg.sender);
    }

    function getPrice() public view returns (uint256) {

        //initial fixed price period or not started
        if (block.timestamp < startTimestamp || startTimestamp == 0) {
            return startPrice;
        }

        uint256 timeElapsed = block.timestamp - startTimestamp;

        //at final price
        if (timeElapsed >= duration){
            return endPrice;
        }

        uint256 discount = discountRate * timeElapsed;
        uint256 price = startPrice - discount;

        if (price < endPrice){
            price = endPrice;
        }
        
        return price;
    }

    function startPublicSale() external onlyOwner {
        //require (startTimestamp == 0,"Already started");
        startTimestamp = block.timestamp + initialPeriod;
        isSaleLive = true;
        emit SaleLive(isSaleLive);
    }

    function stopPublicSale() external onlyOwner ()
    {
        isSaleLive = false;
        emit SaleLive(isSaleLive);
    }

    function setTransactionLimit(uint256 newAmount) external onlyOwner {
        MINTS_PER_TRANSACTION = newAmount;
    }

}