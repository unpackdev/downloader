// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./Strings.sol";

import "./SYNTH3T1C.sol";

//buy with ETH
contract SYNTH3T1CMinter is Ownable {
  
    bool public isSaleLive;

    uint256 public ETH_PER_MINT = 0.2 ether;
    uint256 MAX_PER_MINT = 5;
    
    SYNTH3T1C public SYNTH3T1CToken;

    event SaleLive(bool onSale);

    constructor(address tokenAddress) {
        SYNTH3T1CToken = SYNTH3T1C(tokenAddress);
    }

    function Buy(uint256 amount) external payable {

        require(isSaleLive,"Creation Closed.");
        require(amount > 0,"Zero is a concept.");
        require(amount < MAX_PER_MINT + 1,"Greed.");
        
        uint256 totalCost = ETH_PER_MINT * amount;
        require(msg.value >= totalCost,"Not enough ETH");

        SYNTH3T1CToken.Mint(amount,msg.sender); //mint to sender's wallet
        
    }

    function setSaleLive(bool newStatus) external onlyOwner {
        isSaleLive = newStatus;
        emit SaleLive(isSaleLive);
    }

    function setNFTContract(address tokenAddress) external onlyOwner{
        SYNTH3T1CToken = SYNTH3T1C(tokenAddress);
    }

    function setETHPrice(uint256 newPrice) external onlyOwner {
        ETH_PER_MINT = newPrice;
    }

    function setMaxTransaction(uint256 newMax) external onlyOwner {
        MAX_PER_MINT = newMax;
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}