// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMathUint8 {
 
    function sub(uint8 a, uint8 b) internal pure returns (uint8) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint8 a, uint8 b, string memory errorMessage) internal pure returns (uint8) {
        require(b <= a, errorMessage);
        uint8 c = a - b;

        return c;
    }
}