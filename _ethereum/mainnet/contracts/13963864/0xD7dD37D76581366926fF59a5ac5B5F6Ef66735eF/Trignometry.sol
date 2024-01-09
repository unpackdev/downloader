//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice library to evaluate sin and cos using expanded taylor series by horner's rule.
 */
library Trignometry {

    int256 private constant PRECISION = 64;
    int256 private constant ONE_AT_PRECISION = 18446744073709551616; //2**64
    int256 private constant PI = 57952155664616982739; // PI * ONE_AT_PRECISION

    /**
     * @notice evaluate sin(x).
     * @dev sin(x) != sin(x + 2pi)
     */
    function sin(int256 x) internal pure returns(int256) {
        int256 value;
        assembly {
            let xsq := sar(PRECISION, mul(x, x)) // xsq = x^2
            let xx := add(51862, sar(PRECISION, mul(xsq, sub(0, 151)))) // b8 = 1/17! + xsq*(-1/19!)
            xx := add(sub(0, 14106527), sar(PRECISION, mul(xsq, xx))) // b7 = -1/15! + xsq*b8
            xx := add(2962370717, sar(PRECISION, mul(xsq, xx))) // b6 = 1/13! + xsq*b7
            xx := add(sub(0, 462129831893), sar(PRECISION, mul(xsq, xx))) // b5 = -1/11! + xsq*b6
            xx := add(50834281508238, sar(PRECISION, mul(xsq, xx))) // b4 = 1/9! + xsq*b5
            xx := add(sub(0, 3660068268593165), sar(PRECISION, mul(xsq, xx))) // b3 = -1/7! + xsq*b4
            xx := add(153722867280912930, sar(PRECISION, mul(xsq, xx))) // b2 = 1/5! + xsq*b3
            xx := add(sub(0, 3074457345618258602), sar(PRECISION, mul(xsq, xx))) // b1 = -1/3! + xsq*b2
            xx := add(ONE_AT_PRECISION, sar(PRECISION, mul(xsq, xx))) // t = 1 + xsq*b1
            xx := sar(PRECISION, mul(xx, x)) // sin(x) = t*x
            value := xx
           }
           return value;
       }

    /**
     * @notice evaluate cos(x)
     * @dev cos(x) = sin(90 - x)
     */
    function cos(int256 x) internal pure returns(int256) {
        int256 cx = PI/2 - x;
        if(cx < 0) {
            return -sin(cx * -1); //sin(-x) = -sin(x)
        }
        else {
            return sin(cx);
        }
    }


}