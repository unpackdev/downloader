// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC20.sol";
import "./Ownable.sol";
contract EmeraldMine is ERC20, Ownable {
    bool public tradingActive = true;

    constructor() Ownable(msg.sender) ERC20("Emerald Mine", "MINE") {
      _mint(msg.sender, 5600000000 * 10 ** decimals());
      tradingActive = false;
    }
    
    function enableTrading() external onlyOwner {
        tradingActive = true;
    }
    
    function _update(address from, address to, uint256 value) internal override {
        require(tradingActive, "Trading not active");
        super._update(from, to, value);
    }
      
}
