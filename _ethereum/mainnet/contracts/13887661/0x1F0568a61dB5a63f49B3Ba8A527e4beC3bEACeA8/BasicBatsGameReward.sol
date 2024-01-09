// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BasicBatsPresale.sol";

contract BasicBatsGameReward is BasicBatsPresale {
    
    constructor(string memory _baseURI) BasicBatsPresale(_baseURI) {}
    
    uint[] public winningBatIDs;

    mapping(uint => bool) claims;
    
    uint public prizeReward = 0.05 ether;
    
    function setPrizeReward(uint _amount) external onlyOwner {
        prizeReward = _amount;
    }
    
    function setWinningBats(uint[] calldata _batIDs) external onlyOwner {
        winningBatIDs = _batIDs;
        for(uint i=0; i < _batIDs.length; i++) {
            claims[_batIDs[i]] = false;
        }
    }

    function sendEthForPrize() external payable onlyOwner {

    }
    
    
    function claimReward() external {
        require(address(this).balance >= prizeReward, "Not enough eth in contract");
        
        bool found = false;
        for (uint i = 0; i < winningBatIDs.length; i++) {
            address owner = ownerOf(winningBatIDs[i]);
            if(msg.sender == owner) {
                require(claims[winningBatIDs[i]] == false, "Reward already claimed");
                found = true;
                require(payable(owner).send(prizeReward));
                claims[winningBatIDs[i]] = true;
                break;
            }
        }
        if(!found) {
            revert("You don't own a winning bat");
        }
        
        
    }
    
}