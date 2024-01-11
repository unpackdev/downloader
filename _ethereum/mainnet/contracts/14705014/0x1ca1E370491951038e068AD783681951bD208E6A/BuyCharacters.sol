// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./I_TokenCharacter.sol"; 
import "./Ownable.sol";
import "./PaymentsShared.sol";

contract BuyCharacters is Ownable, PaymentsShared {

    uint256 public constant MAX_MINTABLE = 10000;
    uint256 public TOKEN_PRICE = 0.035 ether;
    uint256 public MINTS_PER_TRANSACTION = 10;

    uint256 public FREE_MINT_AMOUNT = 3500;

    I_TokenCharacter tokenCharacter;

    bool public isSaleLive;
    event SaleLive(bool onSale);

    constructor(address _tokenCharacterAddress) {
        tokenCharacter = I_TokenCharacter(_tokenCharacterAddress);
    }

    function buy(uint8 amountToBuy) external payable {
        require(tx.origin == msg.sender, "EOA only");
        
        require(isSaleLive, "Sale is not live");
        require(amountToBuy <= MINTS_PER_TRANSACTION,"Too many per transaction");

        uint256 totalMinted = tokenCharacter.totalSupply();
        require(totalMinted + amountToBuy <= MAX_MINTABLE,"Sold out");

        uint256 price = 0;

        if (totalMinted > FREE_MINT_AMOUNT) {
            price = TOKEN_PRICE;
        }

        require(msg.value >= price * amountToBuy,"Not enough ETH");

        tokenCharacter.Mint(amountToBuy, msg.sender);
        
    }

    function getPrice() public view returns (uint256) {
        uint256 totalMinted = tokenCharacter.totalSupply();
        
        if (totalMinted > FREE_MINT_AMOUNT) {
            return TOKEN_PRICE;
        }

        return 0; //free mint
    }

    //Variables
    function setPrice(uint256 newPrice) external onlyOwner {
        TOKEN_PRICE = newPrice;
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

    function setFreeAmount(uint256 newAmount) external onlyOwner {
        FREE_MINT_AMOUNT = newAmount;
    }

}