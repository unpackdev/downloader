// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IDividendToken.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract DividendToken is Ownable, IDividendToken {

    using SafeMath for uint256;
    mapping(address => uint256) internal lastPaymentTimestamp;
    mapping(address => bool) internal dividendBlacklist;
    uint256 internal dividendSupply_;

    /**
    * @dev Total dividend supply left
    */
    function totalDividendSupply() external view returns (uint256) {
        return dividendSupply_;
    }

    /**
    * @dev Returns the last payment timestamp of msg sender
    */
    function getLastPaymentTimestamp() external view returns (uint256) {
        return lastPaymentTimestamp[msg.sender];
    }

    /**
    * @dev Transfer tokens to Dividend Supply
    */
    function addToDividendSupply(address from, uint256 value) public returns (bool) {
        dividendSupply_ = dividendSupply_.add(value);
        emit BurnToDividend(from, value);
        return true;
    }

    /**
    * @dev Add to DividendBlacklist
    */
    function updateDividendBlacklist(address targetAddress, bool isBlacklisted) public onlyOwner {
        dividendBlacklist[targetAddress] = isBlacklisted;
        emit DividendBlacklistUpdated(targetAddress, isBlacklisted);
    }
}
