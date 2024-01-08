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
                                                                

            ;`.                       ,'/
            |`.`-.      _____      ,-;,'|
            |  `-.\__,-'     `-.__//'   |
            |     `|               \ ,  |
            `.  ```                 ,  .'
              \_`      \     /      `_/
                \    ^  \   /   ^   /
                 |   X   ____   X  |
                 |     ,'    `.    |
                 |    (  O' O  )   |
                 `.    \__,.__/   ,'
                   `-._  `--'  _,'
                       `------'

created with curiosity by .pwa group 2021.

    gm. wgmi.

            if you're reading this, you are early.

*/

import "./I_TokenBank.sol"; 
import "./Ownable.sol";
import "./Pausable.sol";
import "./PaymentHandler.sol";

contract BuyBanks is Ownable, Pausable, PaymentHandler {

    uint256 public constant MAX_ETH_MINTABLE = 1250;
    uint256 public constant MINTS_PER_TRANSACTION = 3;
    uint256 totalMinted;

    uint256 constant MAX_GIFT = 10;
    uint256 totalGifted;

    I_TokenBank tokenBank;

    constructor(address _tokenBankAddress) {
        tokenBank = I_TokenBank(_tokenBankAddress);
    }

    function GetPrice() public view returns (uint256)
    {        
        if(totalMinted <= 500) {
            return 0.2 ether; }
        else if(totalMinted > 500 && totalMinted <= 800) {
            return 0.5 ether; }
        else if(totalMinted > 800 && totalMinted <= 1000) {
            return 0.7 ether; }
        else if(totalMinted > 1000 && totalMinted <= 1150) {
            return 0.8 ether; }
        else {
            return 1 ether; //more than 1150
        }
    } 

    function Buy(uint256 amountToBuy) external payable whenNotPaused {

        uint256 _ethPrice = GetPrice();

        require(msg.value >= _ethPrice * amountToBuy,"Not enough ETH"); //n.b. slight discount on price boundaries with volume
        require(amountToBuy <= MINTS_PER_TRANSACTION,"Too many per transaction");
                
        require(totalMinted + amountToBuy <= MAX_ETH_MINTABLE,"Sold out");

        uint256 newTotalMinted = totalMinted;
        for (uint256 i = 0; i < amountToBuy; i++ ){
            newTotalMinted += 1;
            tokenBank.Mint(1, msg.sender);
        }
        totalMinted = newTotalMinted;
    }

    function Gift(uint256 amountToGift, address to) external onlyOwner {
        require(totalGifted + amountToGift <= MAX_GIFT,"No more characters left");

        uint256 newTotalGifted = totalGifted;

        for (uint256 i = 0; i < amountToGift; i++ ){
            newTotalGifted += 1;
            tokenBank.Mint(1, to);
        }

        totalGifted = newTotalGifted;
    }

}