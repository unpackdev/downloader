
//socials - Tg: https://t.me/gogofin , Twitter: https://twitter.com/gogofin
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "./ERC20.sol";
import "./Ownable.sol";


                                          
                                           

contract GogoFinance is ERC20, Ownable {


    bool public tradingActive = true;

    constructor() Ownable(msg.sender) ERC20("Gogo Finance", "GOGO") {
      _mint(msg.sender, 10000000000 * 10 ** decimals());
      tradingActive = false;
    }
    
    
     
    function openTrading() external onlyOwner {

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
