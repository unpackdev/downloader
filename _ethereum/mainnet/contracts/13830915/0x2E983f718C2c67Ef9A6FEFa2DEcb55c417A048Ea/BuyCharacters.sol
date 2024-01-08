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

import "./I_TokenCharacter.sol"; 
import "./Ownable.sol";
import "./Pausable.sol";
import "./PaymentHandler.sol";

contract BuyCharacters is Ownable, Pausable, PaymentHandler {

    uint256 public constant MAX_ETH_MINTABLE = 10000;
    uint256 public constant TOKEN_PRICE = 0.07 ether;
    uint256 public constant MINTS_PER_TRANSACTION = 5;
    uint256 totalMinted;

    uint256 constant MAX_GIFT = 200;
    uint256 totalGifted;

    I_TokenCharacter tokenCharacter;

    constructor(address _tokenCharacterAddress) {
        tokenCharacter = I_TokenCharacter(_tokenCharacterAddress);
    }

    function Buy(uint256 amountToBuy) external payable whenNotPaused {
        require(msg.value >= TOKEN_PRICE * amountToBuy,"Not enough ETH");
        require(amountToBuy <= MINTS_PER_TRANSACTION,"Too many per transaction");
                
        require(totalMinted + amountToBuy <= MAX_ETH_MINTABLE,"Sold out");

        uint256 newTotalMinted = totalMinted;
        for (uint256 i = 0; i < amountToBuy; i++ ){
            newTotalMinted += 1;
            tokenCharacter.Mint(1, msg.sender);
        }
        totalMinted = newTotalMinted;
    }

    function Gift(uint256 amountToGift, address to) external onlyOwner {
        require(totalGifted + amountToGift <= MAX_GIFT,"No more characters left");

        uint256 newTotalGifted = totalGifted;
        for (uint256 i = 0; i < amountToGift; i++ ){
            newTotalGifted += 1;
            tokenCharacter.Mint(1, to);
        }
        totalGifted = newTotalGifted;
    }

}