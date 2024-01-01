// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

import "./ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IKyokoPoolAddressesProvider.sol";
import "./IInterestRateStrategy.sol";
import "./DataTypes.sol";
import "./WadRayMath.sol";
import "./PercentageMath.sol";

contract InterestRateStrategy is
    IInterestRateStrategy,
    ContextUpgradeable
{
    using WadRayMath for uint256;
    using PercentageMath for uint256;

    IKyokoPoolAddressesProvider public immutable _addressesProvider;
    mapping(uint256 => DataTypes.Rate) private _ratesList;
    mapping(uint256 => uint256) private _maxVariableBorrowRate;

    modifier onlyKyokoPoolConfigurator() {
        _onlyKyokoPoolConfigurator();
        _;
    }

    function _onlyKyokoPoolConfigurator() internal view {
        require(
            _addressesProvider.isConfigurator(_msgSender()),
            Errors.LP_CALLER_NOT_KYOKO_POOL_CONFIGURATOR
        );
    }

    constructor(
        IKyokoPoolAddressesProvider provider,
        uint256 _optimalUtilizationRate,
        uint256 _baseVariableBorrowRate,
        uint256 _variableRateSlope1,
        uint256 _variableRateSlope2,
        uint256 _baseStableBorrowRate,
        uint256 _stableRateSlope1,
        uint256 _stableRateSlope2
    ) {
        _addressesProvider = provider;
        DataTypes.Rate storage rate = _ratesList[0];
        rate.optimalUtilizationRate = _optimalUtilizationRate;
        rate.excessUtilizationRate = WadRayMath.ray() - _optimalUtilizationRate;
        rate.baseVariableBorrowRate = _baseVariableBorrowRate;
        rate.variableRateSlope1 = _variableRateSlope1;
        rate.variableRateSlope2 = _variableRateSlope2;
        rate.baseStableBorrowRate = _baseStableBorrowRate;
        rate.stableRateSlope1 = _stableRateSlope1;
        rate.stableRateSlope2 = _stableRateSlope2;
        _maxVariableBorrowRate[0] =
            _baseVariableBorrowRate +
            _variableRateSlope1 +
            _variableRateSlope2;
    }

    function getRate(uint256 reserveId)
        external
        view
        override
        returns (DataTypes.Rate memory)
    {
        return _ratesList[reserveId];
    }

    function getMaxVariableBorrowRate(uint256 reserveId)
        external
        view
        override
        returns (uint256)
    {
        return _maxVariableBorrowRate[reserveId];
    }

    /**
     * @dev Calculates the interest rates depending on the reserve's state and configurations
     * @param reserve The address of the reserve
     * @param liquidityAdded The liquidity added during the operation
     * @param liquidityTaken The liquidity taken during the operation
     * @param totalStableDebt The total borrowed from the reserve a stable rate
     * @param totalVariableDebt The total borrowed from the reserve at a variable rate
     * @param averageStableBorrowRate The weighted average of all the stable rate loans
     * @param reserveFactor The reserve portion of the interest that goes to the treasury of the market
     * @return The liquidity rate, the stable borrow rate and the variable borrow rate
     **/
    function calculateInterestRates(
        uint256 reserveId,
        address reserve,
        address kToken,
        uint256 liquidityAdded,
        uint256 liquidityTaken,
        uint256 totalStableDebt,
        uint256 totalVariableDebt,
        uint256 averageStableBorrowRate,
        uint256 reserveFactor
    )
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 availableLiquidity = IERC20Upgradeable(reserve).balanceOf(
            kToken
        );
        //avoid stack too deep
        availableLiquidity =
            availableLiquidity +
            liquidityAdded -
            liquidityTaken;
        DataTypes.Rate memory rate = _ratesList[reserveId];
        return
            calculateInterestRates(
                rate,
                availableLiquidity,
                totalStableDebt,
                totalVariableDebt,
                averageStableBorrowRate,
                reserveFactor
            );
    }

    struct CalcInterestRatesLocalVars {
        uint256 totalDebt;
        uint256 currentVariableBorrowRate;
        uint256 currentStableBorrowRate;
        uint256 currentLiquidityRate;
        uint256 utilizationRate;
    }

    /**
     * @dev Calculates the interest rates depending on the reserve's state and configurations.
     * NOTE This function is kept for compatibility with the previous DefaultInterestRateStrategy interface.
     * New protocol implementation uses the new calculateInterestRates() interface
     * @param rate The info of the rate
     * @param availableLiquidity The liquidity available in the corresponding kToken
     * @param totalStableDebt The total borrowed from the reserve a stable rate
     * @param totalVariableDebt The total borrowed from the reserve at a variable rate
     * @param averageStableBorrowRate The weighted average of all the stable rate loans
     * @param reserveFactor The reserve portion of the interest that goes to the treasury of the market
     * @return The liquidity rate, the stable borrow rate and the variable borrow rate
     **/
    function calculateInterestRates(
        DataTypes.Rate memory rate,
        uint256 availableLiquidity,
        uint256 totalStableDebt,
        uint256 totalVariableDebt,
        uint256 averageStableBorrowRate,
        uint256 reserveFactor
    )
        public
        pure
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        CalcInterestRatesLocalVars memory vars;

        vars.totalDebt = totalStableDebt + totalVariableDebt;
        vars.currentVariableBorrowRate = 0;
        vars.currentStableBorrowRate = 0;
        vars.currentLiquidityRate = 0;

        vars.utilizationRate = vars.totalDebt == 0
            ? 0
            : vars.totalDebt.rayDiv(availableLiquidity + vars.totalDebt);

        vars.currentStableBorrowRate = rate.baseStableBorrowRate;

        if (vars.utilizationRate > rate.optimalUtilizationRate) {
            uint256 excessUtilizationRateRatio = (vars.utilizationRate -
                rate.optimalUtilizationRate).rayDiv(rate.excessUtilizationRate);

            vars.currentStableBorrowRate =
                vars.currentStableBorrowRate +
                rate.stableRateSlope1 +
                rate.stableRateSlope2.rayMul(excessUtilizationRateRatio);

            vars.currentVariableBorrowRate =
                rate.baseVariableBorrowRate +
                rate.variableRateSlope1 +
                rate.variableRateSlope2.rayMul(excessUtilizationRateRatio);
        } else {
            vars.currentStableBorrowRate =
                vars.currentStableBorrowRate +
                rate.stableRateSlope1.rayMul(
                    vars.utilizationRate.rayDiv(rate.optimalUtilizationRate)
                );
            vars.currentVariableBorrowRate =
                rate.baseVariableBorrowRate +
                vars.utilizationRate.rayMul(rate.variableRateSlope1).rayDiv(
                    rate.optimalUtilizationRate
                );
        }

        vars.currentLiquidityRate = _getOverallBorrowRate(
            totalStableDebt,
            totalVariableDebt,
            vars.currentVariableBorrowRate,
            averageStableBorrowRate
        ).rayMul(vars.utilizationRate).percentMul(
                PercentageMath.PERCENTAGE_FACTOR - reserveFactor
            );

        return (
            vars.currentLiquidityRate,
            vars.currentStableBorrowRate,
            vars.currentVariableBorrowRate
        );
    }

    /**
     * @dev Calculates the overall borrow rate as the weighted average between the total variable debt and total stable debt
     * @param totalStableDebt The total borrowed from the reserve a stable rate
     * @param totalVariableDebt The total borrowed from the reserve at a variable rate
     * @param currentVariableBorrowRate The current variable borrow rate of the reserve
     * @param currentAverageStableBorrowRate The current weighted average of all the stable rate loans
     * @return The weighted averaged borrow rate
     **/
    function _getOverallBorrowRate(
        uint256 totalStableDebt,
        uint256 totalVariableDebt,
        uint256 currentVariableBorrowRate,
        uint256 currentAverageStableBorrowRate
    ) internal pure returns (uint256) {
        uint256 totalDebt = totalStableDebt + totalVariableDebt;

        if (totalDebt == 0) return 0;

        uint256 weightedVariableRate = totalVariableDebt.wadToRay().rayMul(
            currentVariableBorrowRate
        );

        uint256 weightedStableRate = totalStableDebt.wadToRay().rayMul(
            currentAverageStableBorrowRate
        );

        uint256 overallBorrowRate = (weightedVariableRate + weightedStableRate)
            .rayDiv(totalDebt.wadToRay());

        return overallBorrowRate;
    }

    /**
     * @dev Set the rate of the specific reserve
     * @param _optimalUtilizationRate The utilization rate at which the pool aims to obtain most competitive borrow rates
     * @param _baseVariableBorrowRate The base variable borrow rate
     * @param _variableSlope1 The slope1 of variable
     * @param _variableSlope2 The slope1 of variable
     * @param _baseStableBorrowRate The base stable borrow rate
     * @param _stableSlope1 The slope1 of stable
     * @param _stableSlope2 The slope2 of stable
     */
    function setRate(
        uint256 reserveId,
        uint256 _optimalUtilizationRate,
        uint256 _baseVariableBorrowRate,
        uint256 _variableSlope1,
        uint256 _variableSlope2,
        uint256 _baseStableBorrowRate,
        uint256 _stableSlope1,
        uint256 _stableSlope2
    ) external override onlyKyokoPoolConfigurator {
        DataTypes.Rate storage rate = _ratesList[reserveId];
        rate.optimalUtilizationRate = _optimalUtilizationRate;
        rate.excessUtilizationRate = WadRayMath.ray() - _optimalUtilizationRate;
        rate.baseVariableBorrowRate = _baseVariableBorrowRate;
        rate.variableRateSlope1 = _variableSlope1;
        rate.variableRateSlope2 = _variableSlope2;
        rate.baseStableBorrowRate = _baseStableBorrowRate;
        rate.stableRateSlope1 = _stableSlope1;
        rate.stableRateSlope2 = _stableSlope2;
        _maxVariableBorrowRate[reserveId] =
            _baseVariableBorrowRate +
            _variableSlope1 +
            _variableSlope2;
    }

    function setVariableRate(
        uint256 reserveId,
        uint256 _baseVariableRate,
        uint256 _variableSlope1,
        uint256 _variableSlope2
    ) external override onlyKyokoPoolConfigurator {
        DataTypes.Rate storage rate = _ratesList[reserveId];
        if (_baseVariableRate > 0) {
            rate.baseVariableBorrowRate = _baseVariableRate;
        }
        if (_variableSlope1 > 0) {
            rate.variableRateSlope1 = _variableSlope1;
        }
        if (_variableSlope2 > 0) {
            rate.variableRateSlope1 = _variableSlope2;
        }
        emit VariableRateUpdated(
            reserveId,
            _baseVariableRate,
            _variableSlope1,
            _variableSlope2
        );
    }

    function setStableRate(
        uint256 reserveId,
        uint256 _baseStableRate,
        uint256 _stableSlope1,
        uint256 _stableSlope2
    ) external override onlyKyokoPoolConfigurator {
        DataTypes.Rate storage rate = _ratesList[reserveId];
        if (_baseStableRate > 0) {
            rate.baseStableBorrowRate = _baseStableRate;
        }
        if (_stableSlope1 > 0) {
            rate.stableRateSlope1 = _stableSlope1;
        }
        if (_stableSlope2 > 0) {
            rate.stableRateSlope2 = _stableSlope2;
        }
        emit StableRateUpdated(
            reserveId,
            _baseStableRate,
            _stableSlope1,
            _stableSlope2
        );
    }
}
