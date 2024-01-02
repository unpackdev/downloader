// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

/*
    telegram: https://t.me/+aj40fT9AT4IxM2Q0
    twitter: https://twitter.com/DarkSoulsERC20
*/

import "./ERC20.sol";
import "./Ownable.sol";

contract DarkSouls is ERC20, Ownable {
    uint256 private initialSupply = 250000000; 
    bool private isBott;
    bool private tradingEnabled; 

    event TradingStatusChanged(bool newStatus);

    constructor() ERC20("Dark Souls Coin", "DSC") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply * 1e18);
        tradingEnabled = true;
    }

    function setTradingStatus(bool _status) public onlyOwner {
        tradingEnabled = _status;
        emit TradingStatusChanged(_status);
    }

    function isTradingEnabled() public view returns (bool) {
        return tradingEnabled;
    }
    
}
