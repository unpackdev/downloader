// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

contract Math {
    /**
        Validates that the first value is less than the second
    */
    modifier lessThan(uint256 _a, uint256 _b) {
        assert(_a < _b);
        _;
    }

    /**
        Returns the sum of _a and _b, asserts if the calculation overflows
    */
    function safeAdd(uint256 _a, uint256 _b) pure internal returns (uint256) {
        uint256 z = _a + _b;
        assert(z >= _a);
        return z;
    }

    /**
        Returns the difference of _a minus _b, asserts if the subtraction results in a negative number
    */
    function safeSub(uint256 _a, uint256 _b) pure internal returns (uint256) {
        assert(_a >= _b);
        return _a - _b;
    }

    /**
        Returns the product of multiplying _a by _b, asserts if the calculation overflows
    */
    function safeMul(uint256 _a, uint256 _b) pure internal returns (uint256) {
        uint256 z = _a * _b;
        assert(_a == 0 || z / _a == _b);
        return z;
    }
}