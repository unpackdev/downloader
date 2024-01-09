// SPDX-License-Identifier:  MIT
pragma solidity 0.8.6;

interface IAnalyticMath {
    /**
     * @dev Compute (a / b) ^ (c / d)
     */
    function pow(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d
    ) external view returns (uint256, uint256);

    function caculateIntPowerSum(uint256 power, uint256 n)
        external
        pure
        returns (uint256);
}
