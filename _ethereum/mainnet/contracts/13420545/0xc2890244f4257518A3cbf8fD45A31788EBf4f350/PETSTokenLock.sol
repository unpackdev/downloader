// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./PETSToken.sol";

// Locks tokens in contract distributing them monthly after an initial lockup period

abstract contract PETSTokenLock is Ownable, ReentrancyGuard {

    string public name;
    uint256 public tgeAt;

    uint256 public maxCap;
    uint256 public numberLockedMonths;
    uint256 public numberUnlockingMonths;
    uint256 public unlockPerMonth;
    uint256 public sent;

    PETSToken public petsToken;

    event Send(address indexed _to, uint256 amount);

    constructor (address _petsTokenAddress) {
        petsToken = PETSToken(_petsTokenAddress);
        tgeAt = 1635422400; // 10-28-2021 12:00:00 UTC
        transferOwnership(0xC179BFF3D9d3700Cf14430DDb37f5adCf4e40108);
    }

   function _getAvailableTokens() internal view  returns (uint256) {
        if(block.timestamp < tgeAt){
            return 0;
        }

        // 2592000 seconds = 30 days
        uint256 months = (block.timestamp - tgeAt) / 2592000;

        if(months >= numberLockedMonths + numberUnlockingMonths){
            //lock is over or events with no lock
            return maxCap - sent;
        }else if(months < numberLockedMonths){
            //too early, tokens are still under full lock;
            return 0;
        }

        
        uint256 potentialAmount = (months - numberLockedMonths) * unlockPerMonth;
        if(potentialAmount > maxCap){//double check, just in case
            potentialAmount = maxCap;
        }
        return potentialAmount - sent;
    }

    function getAvailableTokens() external view returns (uint256) {
        return _getAvailableTokens();
    }

    function send(address to, uint256 amount) onlyOwner nonReentrant external {
        require(sent + amount <= maxCap, "capitalization exceeded");
        
        require(_getAvailableTokens() >= amount, "available amount is less than requested amount");
        sent = sent + amount;
        petsToken.transfer(to, amount);
        emit Send(to,amount);
    }

}