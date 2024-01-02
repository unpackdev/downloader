// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./WadRayMath.sol";
import "./PercentageMath.sol";
import "./DataTypes.sol";
import "./Errors.sol";
import "./IDefaultInterestRateStrategy.sol";
import "./IReserveInterestRateStrategy.sol";
import "./IPoolAddressesProvider.sol";

/**
 * @title DefaultReserveInterestRateStrategy contract
 *
 * @notice Implements the calculation of the interest rates depending on the reserve state
 * @dev The model of interest rate is based on 2 slopes, one before the `OPTIMAL_USAGE_RATIO`
 * point of usage and another from that one to 100%.
 * - An instance of this same contract, can't be used across different YLDR markets, due to the caching
 *   of the PoolAddressesProvider
 */
contract DefaultReserveInterestRateStrategy is IDefaultInterestRateStrategy {
    using WadRayMath for uint256;
    using PercentageMath for uint256;

    /// @inheritdoc IDefaultInterestRateStrategy
    uint256 public immutable OPTIMAL_USAGE_RATIO;

    /// @inheritdoc IDefaultInterestRateStrategy
    uint256 public immutable MAX_EXCESS_USAGE_RATIO;

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    // Base variable borrow rate when usage rate = 0. Expressed in ray
    uint256 internal immutable _baseVariableBorrowRate;

    // Slope of the variable interest curve when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO. Expressed in ray
    uint256 internal immutable _variableRateSlope1;

    // Slope of the variable interest curve when usage ratio > OPTIMAL_USAGE_RATIO. Expressed in ray
    uint256 internal immutable _variableRateSlope2;

    /**
     * @dev Constructor.
     * @param provider The address of the PoolAddressesProvider contract
     * @param optimalUsageRatio The optimal usage ratio
     * @param baseVariableBorrowRate The base variable borrow rate
     * @param variableRateSlope1 The variable rate slope below optimal usage ratio
     * @param variableRateSlope2 The variable rate slope above optimal usage ratio
     */
    constructor(
        IPoolAddressesProvider provider,
        uint256 optimalUsageRatio,
        uint256 baseVariableBorrowRate,
        uint256 variableRateSlope1,
        uint256 variableRateSlope2
    ) {
        require(WadRayMath.RAY >= optimalUsageRatio, Errors.INVALID_OPTIMAL_USAGE_RATIO);
        OPTIMAL_USAGE_RATIO = optimalUsageRatio;
        MAX_EXCESS_USAGE_RATIO = WadRayMath.RAY - optimalUsageRatio;
        ADDRESSES_PROVIDER = provider;
        _baseVariableBorrowRate = baseVariableBorrowRate;
        _variableRateSlope1 = variableRateSlope1;
        _variableRateSlope2 = variableRateSlope2;
    }

    /// @inheritdoc IDefaultInterestRateStrategy
    function getVariableRateSlope1() external view returns (uint256) {
        return _variableRateSlope1;
    }

    /// @inheritdoc IDefaultInterestRateStrategy
    function getVariableRateSlope2() external view returns (uint256) {
        return _variableRateSlope2;
    }

    /// @inheritdoc IDefaultInterestRateStrategy
    function getBaseVariableBorrowRate() external view override returns (uint256) {
        return _baseVariableBorrowRate;
    }

    /// @inheritdoc IDefaultInterestRateStrategy
    function getMaxVariableBorrowRate() external view override returns (uint256) {
        return _baseVariableBorrowRate + _variableRateSlope1 + _variableRateSlope2;
    }

    struct CalcInterestRatesLocalVars {
        uint256 availableLiquidity;
        uint256 totalDebt;
        uint256 currentVariableBorrowRate;
        uint256 currentLiquidityRate;
        uint256 borrowUsageRatio;
        uint256 supplyUsageRatio;
        uint256 availableLiquidityPlusDebt;
    }

    /// @inheritdoc IReserveInterestRateStrategy
    function calculateInterestRates(DataTypes.CalculateInterestRatesParams memory params)
        public
        view
        override
        returns (uint256, uint256)
    {
        CalcInterestRatesLocalVars memory vars;

        vars.totalDebt = params.totalVariableDebt;

        vars.currentLiquidityRate = 0;
        vars.currentVariableBorrowRate = _baseVariableBorrowRate;

        if (vars.totalDebt != 0) {
            vars.availableLiquidity =
                IERC20(params.reserve).balanceOf(params.yToken) + params.liquidityAdded - params.liquidityTaken;

            vars.availableLiquidityPlusDebt = vars.availableLiquidity + vars.totalDebt;
            vars.borrowUsageRatio = vars.totalDebt.rayDiv(vars.availableLiquidityPlusDebt);
            vars.supplyUsageRatio = vars.totalDebt.rayDiv(vars.availableLiquidityPlusDebt);
        }

        if (vars.borrowUsageRatio > OPTIMAL_USAGE_RATIO) {
            uint256 excessBorrowUsageRatio =
                (vars.borrowUsageRatio - OPTIMAL_USAGE_RATIO).rayDiv(MAX_EXCESS_USAGE_RATIO);

            vars.currentVariableBorrowRate += _variableRateSlope1 + _variableRateSlope2.rayMul(excessBorrowUsageRatio);
        } else {
            vars.currentVariableBorrowRate +=
                _variableRateSlope1.rayMul(vars.borrowUsageRatio).rayDiv(OPTIMAL_USAGE_RATIO);
        }

        vars.currentLiquidityRate = _getOverallBorrowRate(params.totalVariableDebt, vars.currentVariableBorrowRate)
            .rayMul(vars.supplyUsageRatio).percentMul(PercentageMath.PERCENTAGE_FACTOR - params.reserveFactor);

        return (vars.currentLiquidityRate, vars.currentVariableBorrowRate);
    }

    /**
     * @dev Calculates the overall borrow rate as the weighted average between the total variable debt and total stable
     * debt
     * @param totalVariableDebt The total borrowed from the reserve at a variable rate
     * @param currentVariableBorrowRate The current variable borrow rate of the reserve
     * @return The weighted averaged borrow rate
     */
    function _getOverallBorrowRate(uint256 totalVariableDebt, uint256 currentVariableBorrowRate)
        internal
        pure
        returns (uint256)
    {
        if (totalVariableDebt == 0) return 0;

        return currentVariableBorrowRate;
    }
}
