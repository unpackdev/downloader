// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./PETSToken.sol";

// Locks tokens in contract distributing them monthly at one rate for a set amount of time, 
// then a second rate, after an initial lockup period

abstract contract PETSTokenLock2Rates is Ownable, ReentrancyGuard {

    string public name;
    uint256 public tgeAt;

    uint256 public maxCap;
    uint256 public numberLockedMonths;
    uint256 public numberUnlockingMonths1;
    uint256 public numberUnlockingMonths2;
    uint256 public unlockPerMonth1;
    uint256 public unlockPerMonth2;
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

        if(months >= numberLockedMonths + numberUnlockingMonths1 + numberUnlockingMonths2){
            //lock is over or events with no lock
            return maxCap - sent;
        }else if(months < numberLockedMonths){
            //too early, tokens are still under full lock;
            return 0;
        }else if(months <= numberLockedMonths + numberUnlockingMonths1){
            uint256 potentialAmount1 = (months - numberLockedMonths) * unlockPerMonth1;
            if(potentialAmount1 > maxCap){//double check, just in case
                potentialAmount1 = maxCap;
            }
            return potentialAmount1 - sent;
        }

        
        uint256 potentialAmount2 = numberUnlockingMonths1 * unlockPerMonth1 +
                                    (months - numberLockedMonths - numberUnlockingMonths1) * unlockPerMonth2;
        if(potentialAmount2 > maxCap){//double check, just in case
            potentialAmount2 = maxCap;
        }
        return potentialAmount2 - sent;
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