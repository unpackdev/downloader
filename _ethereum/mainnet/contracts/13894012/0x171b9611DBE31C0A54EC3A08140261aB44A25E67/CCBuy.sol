// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";

import "./CryptoCookies.sol";

//buy with ETH
contract CCBuy is Ownable {
  
    bool public isSaleLive;

    uint16 constant MAX_ETH_SUPPLY = 20000;
    uint256 public ETH_PER_MINT = 0.05 ether;
    
    CryptoCookies public ccContract;

    event SaleLive(bool onSale);

    constructor(address ccAddress) {
        ccContract = CryptoCookies(ccAddress);
    }

    function Buy(uint16 amount) external payable {

        require(isSaleLive,"Sale not live");
        require(amount > 0,"Mint at least 1");
        require(ccContract._totalMinted() + amount <= MAX_ETH_SUPPLY,"Max tokens minted");
        
        uint256 totalCost = ETH_PER_MINT * amount;
        require(msg.value >= totalCost,"Not enough ETH");

        for (uint256 i = 0; i < amount; i++ ){
           ccContract.mintExternal(msg.sender, ccContract._totalMinted() + 1); //mint to sender's wallet
        }

    }

    function toggleSaleStatus() external onlyOwner {
        isSaleLive = !isSaleLive;
        emit SaleLive(isSaleLive);
    }

    function setCCContract(address ccAddress) external onlyOwner{
        ccContract = CryptoCookies(ccAddress);
    }

    function setETHPrice(uint256 newPrice) external onlyOwner {
        ETH_PER_MINT = newPrice;
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}