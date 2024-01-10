// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;
import "./Owned.sol";

contract CrowdSaleBonus is Owned {
    uint256 public multiplier;
    uint256 public decimals;
    uint256 public startTime;
    uint256 public endTime;

    constructor(uint256 _multiplier, uint256 _decimals, uint256 _startTime, uint256 _endTime) lessThan(_startTime, _endTime) {
        multiplier = _multiplier;
        decimals = _decimals;
        startTime = _startTime;
        endTime = _endTime;
    }

    /**
        Checks if the bonus is active
    */
    function isActive() public view returns (bool) {
        if (block.timestamp < startTime || block.timestamp > endTime) {
            return false;
        }
        return true;
    }

    /**
        Gets the amount with the bonus included
    */
    function calculateAmountWithBonus(uint256 _amount) public view returns (uint256) {
        uint256 divisor = 10 ** decimals;
        uint256 divided = divisor > 0 ? (_amount / divisor) : _amount;
        return safeMul(divided, multiplier);
    }
}