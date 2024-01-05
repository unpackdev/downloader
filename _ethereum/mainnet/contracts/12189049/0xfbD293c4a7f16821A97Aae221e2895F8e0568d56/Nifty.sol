// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./IUniswapV2Pair.sol";
import "./ERC20.sol";
import "./Ownable.sol";

contract Nifty is ERC20("Nifty Packs", "NFTY"), Ownable {

    mapping(address => bool) public whitelist;
    bool public locked;
    
    constructor(uint256 totalSupply) {
        locked = true;
        _mint(msg.sender, totalSupply * (10 ** 18));
    }

    function unlock() public onlyOwner {
        locked = false;
    } 

    function lock() public onlyOwner {
        locked = true;
    }

    function addToWhitelist(address _user) public onlyOwner {
        whitelist[_user] = true;
    }

    function removeFromWhitelist(address _user) public onlyOwner {
        whitelist[_user] = false;
    }
    
    function transfer(address to, uint256 amount) public override returns (bool) {
        if(locked) {
            require(msg.sender == owner() || whitelist[msg.sender]);
        }
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        if(locked) {
            require(from == owner() || whitelist[from]);
        }
        return super.transferFrom(from, to, amount);
    }
   
}
