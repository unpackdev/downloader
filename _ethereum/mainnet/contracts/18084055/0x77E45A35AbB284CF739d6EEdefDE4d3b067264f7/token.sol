
// https://t.me/RepublicofPeczech https://rop420.com
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract ROP420 is ERC20, Ownable { 

    uint256 public whaleAmount;
    uint256 public taxRateBuy;
    uint256 public taxRateSell;
    address public taxDestination;
    address public tradingPair;

    constructor() ERC20("Republic of Peczech", "ROP420") {
        _mint(msg.sender, 42000000 * 10 ** decimals());
    }

    function setWhaleAmount(uint256 _whaleAmount) external onlyOwner {
        whaleAmount = _whaleAmount;
    }

    function setBuyTaxRate(uint256 _taxRate) external onlyOwner {
        taxRateBuy = _taxRate;
    }

    function setSellTaxRate(uint256 _taxRate) external onlyOwner {
        taxRateSell = _taxRate;
    }

    function setTaxDestination(address _taxDestination) external onlyOwner {
        taxDestination = _taxDestination;
    }

    function setTradingPair(address _tradingPair) external onlyOwner {
        tradingPair = _tradingPair;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal virtual override 
    {
        super._beforeTokenTransfer(from, to, amount); 
        if (! (tx.origin == owner() || to == tradingPair) ) {
            require(balanceOf(to) + amount <= whaleAmount, "Owner has too much!");
        }
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        // trading case (buy)
        if (msg.sender == owner()) {
            super._transfer(from, to, amount);
        }
        else if (from == tradingPair) {
            uint256 tax = amount * taxRateBuy / 1 ether;
            super._transfer(from, to, amount - tax);
            super._transfer(from, taxDestination, tax);
        }

        // trading case (sell)
        else if (to == tradingPair) {
            uint256 tax = amount * taxRateSell / 1 ether;
            super._transfer(from, to, amount - tax - 1);
            super._transfer(from, taxDestination, tax);
        }
        
        // normal case
        else {
            super._transfer(from, to, amount - 1);
        }
    }
}