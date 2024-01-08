// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library SafeMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a - b;
        require(c <= a, "SafeMath: subtraction overflow");
        return c;
    }

    function mul(uint32 a, uint32 b) internal pure returns (uint32) {
        if (a == 0) {
            return 0;
        }
        uint32 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b > 0, "SafeMath: division by zero");
        uint32 c = a / b;
        return c;
    }
}
