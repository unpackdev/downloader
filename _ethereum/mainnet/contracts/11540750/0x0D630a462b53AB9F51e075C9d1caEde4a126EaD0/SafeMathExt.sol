pragma solidity ^0.7.3;

import "./SafeMath.sol";

library SafeMathExt {

    using SafeMath for uint256;

    uint256 public constant UNIT8 = 1e8;
    uint256 public constant UNIT18 = 1e18;

    function base10pow(uint8 exponent) internal pure returns (uint256) {
        // very common
        if (exponent == 18) return 1e18;
        if (exponent == 6) return 1e6;

        uint256 result = 1;

        while (exponent >= 10) {
            result = result.mul(uint256(1e10));
            exponent -= 10;
        }

        while (exponent > 0) {
            result = result.mul(uint256(10));
            exponent--;
        }

        return result;
    }

    function mulDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.mul(y) / UNIT18;
    }

    function divDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.mul(UNIT18).div(y);
    }

    function mulDecimal8(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.mul(y) / UNIT8;
    }

    function divDecimal8(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.mul(UNIT8).div(y);
    }

    function safeUint64(uint256 x) internal pure returns (uint64) {
        require(x <= uint64(-1), 'SafeMath: cast overflow');
        return uint64(x);
    }

}