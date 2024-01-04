// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MathHelpers {
    uint256 public constant divisionDenominator = 10**18;

    function _multiplyWithNumerator(uint256 _amount, uint256 _numerator) internal pure returns(uint256) {
        return((_amount * _numerator) / divisionDenominator);
    }
}
