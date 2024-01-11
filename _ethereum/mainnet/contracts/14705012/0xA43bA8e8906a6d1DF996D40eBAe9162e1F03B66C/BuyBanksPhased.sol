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
//import "./ECDSA.sol";

import "./PaymentsShared.sol";
import "./I_TokenBank.sol";

contract BuyBanksPhased is Ownable, PaymentsShared {

    uint256 public constant MAX_MINTABLE = 1250;
    uint256 public MINTS_PER_TRANSACTION = 5;
    bool public isSaleLive;

    I_TokenBank tokenBank;

    //events
    event SaleLive(bool onSale);

    constructor(address _tokenBankAddress) {
        tokenBank = I_TokenBank(_tokenBankAddress);
    }

    function buy(uint8 amountToBuy) external payable {
        require(tx.origin == msg.sender, "EOA only");

        require(isSaleLive, "Sale is not live");
        require(msg.value >= getPrice() * amountToBuy,"Not enough ETH");        

        require(amountToBuy < MINTS_PER_TRANSACTION + 1,"Over max per transaction");
        require(tokenBank.totalSupply() + amountToBuy < MAX_MINTABLE + 1,"Sold out");
    
        //Do minting
        tokenBank.Mint(amountToBuy, msg.sender);
    }

    function getPrice() public view returns (uint256) {

        uint256 supply = tokenBank.totalSupply();

        if (supply < 400){
            return 0.1 ether;
        } else if (supply < 600){
            return 0.2 ether;
        } else if (supply < 800){
            return 0.3 ether;
        } else if (supply < 1000){
            return 0.4 ether;
        }
        
        return 0.5 ether;
    }

    function startPublicSale() external onlyOwner {
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