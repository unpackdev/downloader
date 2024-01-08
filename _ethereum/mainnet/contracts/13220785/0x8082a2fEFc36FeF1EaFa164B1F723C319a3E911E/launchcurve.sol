// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeMath.sol";

contract LaunchCurveExponential {
    using SafeMath for uint256;
    // This contract only works with 18 decimal tokens
    uint256 private decimals = 10**18;

    /**
     * @dev Calculate the return shares of a stake based on a total supply,
     * pool balance and a reducer factor.
     *
     * Returns the amount of tokens that user will receive in return of staked amount.
     * In case of stake not be 18 decimal, is needed to normalize it.
     *
     * Requirements:
     *
     * - `supply` The total supply of the launch pool.
     * - `pool` The current balance of the pool to be calculated.
     * - `stake` The current stake to return the amount of tokens to return.
     * - `reducer` The reducerr factor to make curve less exponential. Recommended 1 to 400.
    **/
    function getShares(uint256 supply, uint256 pool, uint256 stake, uint256 reducer, uint256 minPrice) public view returns(uint256) {
        uint256 curve = (pool*pool).div(supply*100000*reducer);
        uint256 unitPrice = curve+minPrice;
        return stake.mul(decimals).div(unitPrice);
    }

    function getUnitPrice(uint256 supply, uint256 pool, uint256 reducer, uint256 minPrice) public pure returns(uint256) {
        uint256 curve = (pool*pool).div(reducer*100000*supply);
        return curve+minPrice;
    }

    function getCurve(uint256 supply, uint256 pool, uint256 reducer) public pure returns(uint256) {
        return (pool*pool).div(reducer*100000*supply);
    }
}