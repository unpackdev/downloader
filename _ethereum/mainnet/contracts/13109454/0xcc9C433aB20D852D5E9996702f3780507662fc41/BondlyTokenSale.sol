// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./BondlyToken.sol";

abstract contract BondlyTokenSale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    string public name;
    uint256 public maxCap;
    //uint256 public totalReserved;
    uint256 public totalTransferred;
    uint256 public fullLockMonths;
    uint256 public unlockRate;
    uint256 public floatingRate;
   
    BondlyToken public bondToken;

    struct iTokenLock {
        uint256 lastTxAt;
        uint256 amount;
        uint256 sent;
    }

    mapping (address => iTokenLock) public eLog;
    //event TokensSend(address indexed contributor, uint tokensSentS);

    constructor (address _bondTokenAddress) public {
        bondToken = BondlyToken(_bondTokenAddress);
    }
    
    function _getAvailableTokens(address _address) internal view  returns (uint256) {

        uint256 months = block.timestamp.sub(eLog[_address].lastTxAt).div(2592000);

        if(months >= fullLockMonths+unlockRate){
            //lock is over or events with no lock, example: Initial DEX offering
            return eLog[_address].amount.sub(eLog[_address].sent);
        }else if(months < fullLockMonths){
            //too early, tokens are still under full lock;
            return 0;
        }
    
        uint256 potentialAmount;
        if(floatingRate == 5025){
            //events with floating (50%25%) unlock rate, example: Pre-Offering, Bondly Card Game
            uint256 firstMonth = eLog[_address].amount.div(2);
            uint256 nextMonths = firstMonth.div(2);
            potentialAmount = (months-fullLockMonths).mul(nextMonths).add(firstMonth);
        }else{
            //events with stable unlock rate, example: Seed, P1, P2
            //+1 due to beginning of a month
            potentialAmount = (eLog[_address].amount).mul(months-fullLockMonths+1).div(unlockRate);
        }

        if(potentialAmount > eLog[_address].amount){//double check, just in case
            potentialAmount = eLog[_address].amount;
        }
        return potentialAmount.sub(eLog[_address].sent);
    }

    function getAvailableTokens() external view returns (uint256) {
        return _getAvailableTokens(msg.sender);
    }

    function getAvailableTokensByAddress(address _address) external view returns (uint256) {
        return _getAvailableTokens(_address);
    }

    /*function addContributor(address _address, uint256 lastTxAt, uint256 amount) onlyOwner external {
        require(eLog[_address].amount == 0, "Contributor already added");
        require(amount > 0, "amount is 0");
        require(totalReserved.add(amount) <= maxCap, "Total Sale Supply overflow");

        totalReserved = totalReserved.add(amount);
        
        eLog[_address] = iTokenLock({ 
            lastTxAt: lastTxAt,
            amount: amount, 
            sent: 0
        });
    }*/

    function claim(uint256 amount) nonReentrant external {
        require(eLog[msg.sender].sent.add(amount) <= eLog[msg.sender].amount, "Contribution capitalization exceeded");
        require(_getAvailableTokens(msg.sender) >= amount, "Available amount is less than requested amount");

        eLog[msg.sender].sent = eLog[msg.sender].sent.add(amount);
        totalTransferred = totalTransferred.add(amount);
        bondToken.transfer(msg.sender, amount);
    }


    function transfer(address to, uint256 amount) nonReentrant onlyOwner external {
        require(eLog[to].sent.add(amount) <= eLog[to].amount, "Contribution capitalization exceeded");
        require(_getAvailableTokens(to) >= amount, "Available amount is less than requested amount");

        eLog[to].sent = eLog[to].sent.add(amount);
        totalTransferred = totalTransferred.add(amount);
        bondToken.transfer(to, amount);
    }

    function getContributionInfo(address _address) external view returns (uint256, uint256, uint256) {
        return(eLog[_address].amount, eLog[_address].lastTxAt, eLog[_address].sent);
    }
}