pragma solidity ^0.6.0;

library Math {
    /**
     * @dev Returns max value of 2 unsigned ints
     */
    function umax(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns min value of 2 unsigned ints
     */
    function umin(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns max value of 2 signed ints
     */
    function max(int a, int b) internal pure returns (int) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns min value of 2 signed ints
     */
    function min(int a, int b) internal pure returns (int) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the positive delta between 2 unsigned ints
     */
    function udelta(uint a, uint b) internal pure returns (uint) {
        return a > b ? a - b : b - a;
    } 
    /**
     * @dev Returns the positive delta between 2 signed ints
     */
    function delta(int a, int b) internal pure returns (int) {
        return a > b ? a - b : b - a;
    } 
}
