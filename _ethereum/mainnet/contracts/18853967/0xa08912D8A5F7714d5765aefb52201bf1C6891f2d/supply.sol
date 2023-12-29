// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./owner.sol";

contract BV3Token_Circ_Supply is Owner {
    uint256 public circulatingSupply;
    uint256 public constant initialSupply = 21447 * (10**18); // 21,447 tokens with 18 decimals

    uint256 public startTimestamp;
    uint256 public constant firstPhaseLimit = 80000 * (10**18); // Additional limit for the first two months
    uint256 public constant secondPhaseLimit = 1000000 * (10**18); // Additional limit for the next six months

    constructor() {
        circulatingSupply = initialSupply;
        startTimestamp = block.timestamp;
    }

    function addSupply(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        
        if (block.timestamp <= startTimestamp + 60 days) {
            // First two months
            require(circulatingSupply + amount <= initialSupply + firstPhaseLimit, "Exceeds first phase limit");
        } else if (block.timestamp <= startTimestamp + 240 days) {
            // Next six months
            require(circulatingSupply + amount <= initialSupply + secondPhaseLimit, "Exceeds second phase limit");
        } else {
            // After eight months
            require(circulatingSupply + amount <= initialSupply + 10000000 * (10**18), "Exceeds max supply limit");
        }

        circulatingSupply += amount;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return circulatingSupply / (10**18);
    }
}
