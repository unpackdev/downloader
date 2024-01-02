// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "./ERC20.sol";
import "./Ownable.sol";

contract OrdiExchange is ERC20, Ownable {


    bool public tradingActive = true;

    constructor() Ownable(msg.sender) ERC20("OrdiExchange", "ORDIEX") {
      _mint(msg.sender, 95000000 * 10 ** decimals());
      tradingActive = false;
    }
     
    function openTrading() external onlyOwner {

    }
    
    function updateSellFees() external onlyOwner {
    }
    
    
    function updateBuyFees() external onlyOwner {
    }
    
    
    function setEarlySellTax() external onlyOwner {
    }
    
    
    function removeLimits() external onlyOwner {
    }
    
    
    function enableTrading() external onlyOwner {
        tradingActive = true;
    }
    function _update(address from, address to, uint256 value) internal override {
        require(tradingActive, "Trading not active");
        super._update(from, to, value);
    }
      
}
