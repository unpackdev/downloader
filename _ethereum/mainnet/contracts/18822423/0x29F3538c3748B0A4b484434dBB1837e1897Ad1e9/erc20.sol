// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC20.sol";
import "./Ownable.sol";
contract SLEEPTOKEN is ERC20, Ownable {
    bool public tradingActive = true;

    constructor() Ownable(msg.sender) ERC20("SLEEP TOKEN", "SLEEP") {
      _mint(msg.sender, 1000000000 * 10 ** decimals());
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
