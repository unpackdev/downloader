// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./BondlyToken.sol";

abstract contract BondlyTokenHolder is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    string public name;
    uint256 public createdAt;

    uint256 public maxCap;
    uint256 public fullLockMonths;
    uint256 public unlockRate;
    uint256 public perMonth;
    uint256 public sent;

    BondlyToken public bondToken;

    constructor (address _bondTokenAddress) public {
        bondToken = BondlyToken(_bondTokenAddress);
        createdAt = 1607349617;//block.timestamp
    }

   function _getAvailableTokens() internal view  returns (uint256) {

        uint256 months = block.timestamp.sub(createdAt).div(2592000);

        if(months >= fullLockMonths+unlockRate){
            //lock is over or events with no lock, example: Initial DEX offering
            return maxCap.sub(sent);
        }else if(months < fullLockMonths){
            //too early, tokens are still under full lock;
            return 0;
        }

        //+1 due to beginning of a month
        uint256 potentialAmount = (months-fullLockMonths+1).mul(perMonth);
        if(potentialAmount > maxCap){//double check, just in case
            potentialAmount = maxCap;
        }
        return potentialAmount.sub(sent);
    }

    function getAvailableTokens() external view returns (uint256) {
        return _getAvailableTokens();
    }

    function send(address to, uint256 amount) onlyOwner nonReentrant external {
        require(sent.add(amount) <= maxCap, "capitalization exceeded");
        
        require(_getAvailableTokens() >= amount, "available amount is less than requested amount");
        sent = sent.add(amount);
        bondToken.transfer(to, amount);
    }

}