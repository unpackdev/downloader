// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library SafeMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64) {
        uint64 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64) {
        uint64 c = a - b;
        require(c <= a, "SafeMath: subtraction overflow");
        return c;
    }

    function mul(uint64 a, uint64 b) internal pure returns (uint64) {
        if (a == 0) {
            return 0;
        }
        uint64 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b > 0, "SafeMath: division by zero");
        uint64 c = a / b;
        return c;
    }
}