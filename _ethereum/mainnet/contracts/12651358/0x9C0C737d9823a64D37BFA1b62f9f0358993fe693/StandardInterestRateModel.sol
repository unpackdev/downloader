// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMathUpgradeable.sol";
import "./SafeRatioMath.sol";

/**
 * @title dForce's lending InterestRateModel Contract
 * @author dForce
 */
contract StandardInterestRateModel {
    using SafeMathUpgradeable for uint256;
    using SafeRatioMath for uint256;

    uint256 private constant BASE = 1e18;

    /**
     * @notice The approximate number of Ethereum blocks produced each year
     */
    uint256 public constant blocksPerYear = 2425846;

    /**
     * @notice Threshold utilization
     */
    uint256 public threshold;

    /**
     * @notice Construct an interest rate model
     * @param _threshold Threshold utilization, 18 decimal places
     */
    constructor(uint256 _threshold) public {
        threshold = _threshold;
    }

    /*********************************/
    /******** Security Check *********/
    /*********************************/

    /**
     * @notice Ensure this is an interest rate model contract.
     */
    function isInterestRateModel() external pure returns (bool) {
        return true;
    }

    /**
     * @notice Calculate the utilization rate: `_borrows / (_cash + _borrows - _reserves)`
     * @param _cash Asset balance
     * @param _borrows Asset borrows
     * @param _reserves Asset reserves
     * @return Asset utilization [0, 1e18]
     */
    function utilizationRate(
        uint256 _cash,
        uint256 _borrows,
        uint256 _reserves
    ) internal pure returns (uint256) {
        // Utilization rate is 0 when there are no borrows
        if (_borrows == 0) return 0;

        // Utilization rate is 100% when _grossSupply is less than or equal to borrows
        uint256 _grossSupply = _cash.add(_borrows);
        if (_grossSupply <= _reserves) return BASE;

        // Utilization rate is 100% when _borrows is greater than _supply
        uint256 _supply = _grossSupply.sub(_reserves);
        if (_borrows > _supply) return BASE;

        return _borrows.mul(BASE).div(_supply);
    }

    /**
     * @notice Get the current borrow rate per block, 18 decimal places
     * @param _balance Asset balance
     * @param _borrows Asset borrows
     * @param _reserves Asset reserves
     * @return _borrowRate Current borrow rate APR
     */
    function getBorrowRate(
        uint256 _balance,
        uint256 _borrows,
        uint256 _reserves
    ) external view returns (uint256 _borrowRate) {
        uint256 _util = utilizationRate(_balance, _borrows, _reserves);

        uint256 _threshold = threshold;

        // Borrow rate is:
        // 1). 0% <= UR < 5%:   0.02*UR^2 + 0.08*UR^4 + 0.05*UR^7
        // 2). 5% <= UR < 100%: 0.05*UR^2 + 0.08*UR^4 + 0.05*UR^7
        uint256 _factor = _util < _threshold ? 10 : 25;
        uint256 _temp = _util.rpow(2, BASE).mul(_factor);
        _temp = _temp.add(_util.rpow(4, BASE).mul(40));
        _temp = _temp.add(_util.rpow(7, BASE).mul(25));

        uint256 _annualBorrowRateScaled = _temp.mul(2).div(1000);

        // And then divide down by blocks per year.
        _borrowRate = _annualBorrowRateScaled.div(blocksPerYear);
    }
}
