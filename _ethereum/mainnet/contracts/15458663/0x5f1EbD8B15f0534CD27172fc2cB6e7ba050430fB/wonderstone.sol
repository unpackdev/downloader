// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.8;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Capped.sol";
import "./SafeMath.sol";

using SafeMath for uint256;

contract WonderStone is ERC20Capped, Ownable {
    uint256 constant CAP = 10000000 * 10 ** 18;
    
    constructor() ERC20("WonderStone", "WST") ERC20Capped(CAP) {
        _mint(msg.sender, CAP);
    }

    /**
     * @dev function to remove stuck tokens from the contract
     */
    function withdrawToOwner() external onlyOwner {
        uint256 balance = balanceOf(address(this));
        
        require(balance > 0, "Contract has no balance");
        require(this.transfer(owner(), balance), "Transfer failed");
    }
}