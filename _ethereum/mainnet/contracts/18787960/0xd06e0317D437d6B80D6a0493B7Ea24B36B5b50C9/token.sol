// contracts/token.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Capped.sol";

contract Token is Ownable, ERC20Capped {
    uint8 private _decimals;

    constructor(
        uint256 initialSupply, 
        string memory tokenName, 
        string memory tokenSymbol, 
        uint8 tokenDecimals,
        uint256 cap) Ownable (msg.sender) ERC20(tokenName, tokenSymbol) ERC20Capped(cap){
        _decimals = tokenDecimals;
        _mint(msg.sender, initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function burn(uint256 amount) public onlyOwner returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }

    function mint(address account, uint256 amount) public onlyOwner returns (bool) {
        _mint(account, amount);
        return true;
    }
}