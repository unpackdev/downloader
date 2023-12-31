// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./IMToken.sol";
import "./IDebtToken.sol";
import "./IInterestRate.sol";
import "./ReserveConfiguration.sol";
import "./MathUtils.sol";
import "./WadRayMath.sol";
import "./PercentageMath.sol";
import "./Errors.sol";
import "./DataTypes.sol";

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

/**
 * @title ReserveLogic library
 * @author MetaFire
 * @notice Implements the logic to update the reserves state
 */
library ReserveLogic {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /**
   * @dev Emitted when the state of a reserve is updated
   * @param asset The address of the underlying asset of the reserve
   * @param liquidityRates The new liquidity rate list
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndices The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed asset,
    uint256[4] liquidityRates,
    uint256 variableBorrowRate,
    uint128[4] liquidityIndices,
    uint256 variableBorrowIndex
  );

  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  /**
   * @dev Returns the ongoing normalized income for the reserve
   * A value of 1e27 means there is no income. As time passes, the income is accrued
   * A value of 2*1e27 means for each unit of asset one unit of income has been accrued
   * @param reserve The reserve object
   * @return the normalized income. expressed in ray
   **/
   // @Todo: update timestamp choosing
  function getNormalizedIncome(DataTypes.ReserveData storage reserve, DataTypes.Period period) internal view returns (uint256) {
    uint8 period = uint8(period);
    uint40 timestamp = reserve.lastUpdateTimestamp;

    //solium-disable-next-line
    if (timestamp == uint40(block.timestamp)) {
      //if the index was updated in the same block, no need to perform any calculation
      return reserve.liquidityIndices[period];
    }

    uint256 cumulated = MathUtils.calculateLinearInterest(reserve.currentLiquidityRates[period], timestamp).rayMul(
      reserve.liquidityIndices[period]
    );

    return cumulated;
  }

  /**
   * @dev Returns the ongoing normalized variable debt for the reserve
   * A value of 1e27 means there is no debt. As time passes, the income is accrued
   * A value of 2*1e27 means that for each unit of debt, one unit worth of interest has been accumulated
   * @param reserve The reserve object
   * @return The normalized variable debt. expressed in ray
   **/
  function getNormalizedDebt(DataTypes.ReserveData storage reserve) internal view returns (uint256) {
    uint40 timestamp = reserve.lastUpdateTimestamp;

    //solium-disable-next-line
    if (timestamp == uint40(block.timestamp)) {
      //if the index was updated in the same block, no need to perform any calculation
      return reserve.variableBorrowIndex;
    }

    uint256 cumulated = MathUtils.calculateCompoundedInterest(reserve.currentVariableBorrowRate, timestamp).rayMul(
      reserve.variableBorrowIndex
    );

    return cumulated;
  }

  /**
   * @dev Updates the liquidity cumulative index and the variable borrow index.
   * @param reserve the reserve object
   **/
  function updateState(DataTypes.ReserveData storage reserve) internal {
    uint256 scaledVariableDebt = IDebtToken(reserve.debtTokenAddress).scaledTotalSupply();
    uint256 previousVariableBorrowIndex = reserve.variableBorrowIndex;
    uint128[4] memory previousLiquidityIndices = reserve.liquidityIndices;
    uint40 lastUpdatedTimestamp = reserve.lastUpdateTimestamp;

    (uint256[4] memory newLiquidityIndices, uint256 newVariableBorrowIndex) = _updateIndexes(
      reserve,
      scaledVariableDebt,
      previousLiquidityIndices,
      previousVariableBorrowIndex,
      lastUpdatedTimestamp
    );

    _mintToTreasury(
      reserve,
      scaledVariableDebt,
      previousVariableBorrowIndex,
      newLiquidityIndices,
      newVariableBorrowIndex,
      lastUpdatedTimestamp
    );
  }

  /**
   * @dev Accumulates a predefined amount of asset to the reserve as a fixed, instantaneous income. Used for example to accumulate
   * the flashloan fee to the reserve, and spread it between all the depositors
   * @param reserve The reserve object
   * @param totalLiquidity The total liquidity available in the reserve
   * @param amount The amount to accomulate
   **/
  function cumulateToLiquidityIndex(
    DataTypes.ReserveData storage reserve,
    uint256 totalLiquidity,
    uint256 amount,
    uint8 period
  ) internal {
    uint256 amountToLiquidityRatio = amount.wadToRay().rayDiv(totalLiquidity.wadToRay());

    uint256 result = amountToLiquidityRatio + (WadRayMath.ray());

    result = result.rayMul(reserve.liquidityIndices[period]);
    require(result <= type(uint128).max, Errors.RL_LIQUIDITY_INDEX_OVERFLOW);

    reserve.liquidityIndices[period] = uint128(result);
  }

  /**
   * @dev Initializes a reserve
   * @param reserve The reserve object
   * @param mTokenAddresses The address of the overlying mToken contract
   * @param debtTokenAddress The address of the overlying debtToken contract
   * @param interestRateAddress The address of the interest rate strategy contract
   **/
  function init(
    DataTypes.ReserveData storage reserve,
    address[4] memory mTokenAddresses,
    address debtTokenAddress,
    address interestRateAddress
  ) external {
    for (uint256 i = 0; i < reserve.mTokenAddresses.length; i++) {
        require(reserve.mTokenAddresses[i] == address(0), Errors.RL_RESERVE_ALREADY_INITIALIZED);
    }

    uint128[4] memory liquidityIndices = [uint128(WadRayMath.ray()),uint128(WadRayMath.ray()),uint128(WadRayMath.ray()),uint128(WadRayMath.ray())];
    
    reserve.liquidityIndices = liquidityIndices;
    reserve.variableBorrowIndex = uint128(WadRayMath.ray());
    reserve.mTokenAddresses = mTokenAddresses;
    reserve.debtTokenAddress = debtTokenAddress;
    reserve.interestRateAddress = interestRateAddress;
  }

  struct UpdateInterestRatesLocalVars {
    uint256 availableLiquidity;
    uint256[4] newLiquidityRates;
    uint256 newVariableRate;
    uint256 totalVariableDebt;
  }

  /**
   * @dev Updates the reserve current stable borrow rate, the current variable borrow rate and the current liquidity rate
   * @param reserve The address of the reserve to be updated
   * @param liquidityAdded The amount of liquidity added to the protocol (deposit or repay) in the previous action
   * @param liquidityTaken The amount of liquidity taken from the protocol (withdraw or borrow)
   **/
  function updateInterestRates(
    DataTypes.ReserveData storage reserve,
    address reserveAddress,
    address targetMTokenAddress,
    uint256 liquidityAdded,
    uint256 liquidityTaken
  ) internal {
    DataTypes.ReserveData memory _reserve = reserve;
    UpdateInterestRatesLocalVars memory vars;
    uint256 currentTotalLiquidity;

    //calculates the total variable debt locally using the scaled borrow amount instead
    //of borrow amount(), as it's noticeably cheaper. Also, the index has been
    //updated by the previous updateState() call
    vars.totalVariableDebt = IDebtToken(reserve.debtTokenAddress).scaledTotalSupply().rayMul(
      reserve.variableBorrowIndex
    );

    (vars.newLiquidityRates, vars.newVariableRate) = IInterestRate(reserve.interestRateAddress).calculateInterestRates(
      _reserve,
      targetMTokenAddress,
      liquidityAdded,
      liquidityTaken,
      vars.totalVariableDebt,
      reserve.configuration.getReserveFactor()
    );

    require(vars.newVariableRate <= type(uint128).max, Errors.RL_VARIABLE_BORROW_RATE_OVERFLOW);
    for (uint256 i = 0; i < vars.newLiquidityRates.length; i++) {
      require(vars.newLiquidityRates[i] <= type(uint128).max, Errors.RL_LIQUIDITY_RATE_OVERFLOW);
      reserve.currentLiquidityRates[i] = uint128(vars.newLiquidityRates[i]);
    }
    
    
    reserve.currentVariableBorrowRate = uint128(vars.newVariableRate);

    emit ReserveDataUpdated(
      reserveAddress,
      vars.newLiquidityRates,
      vars.newVariableRate,
      reserve.liquidityIndices,
      reserve.variableBorrowIndex
    );
  }

  struct MintToTreasuryLocalVars {
    uint256 currentVariableDebt;
    uint256 previousVariableDebt;
    uint256 totalDebtAccrued;
    uint256 amountToMint;
    uint256 reserveFactor;
  }

  /**
   * @dev Mints part of the repaid interest to the reserve treasury as a function of the reserveFactor for the
   * specific asset.
   * @param reserve The reserve reserve to be updated
   * @param scaledVariableDebt The current scaled total variable debt
   * @param previousVariableBorrowIndex The variable borrow index before the last accumulation of the interest
   * @param newLiquidityIndices The new liquidity index
   * @param newVariableBorrowIndex The variable borrow index after the last accumulation of the interest
   * @param timestamp The timestamp of the action
   **/
  function _mintToTreasury(
    DataTypes.ReserveData storage reserve,
    uint256 scaledVariableDebt,
    uint256 previousVariableBorrowIndex,
    uint256[4] memory newLiquidityIndices,
    uint256 newVariableBorrowIndex,
    uint40 timestamp
  ) internal {
    timestamp;
    MintToTreasuryLocalVars memory vars;

    vars.reserveFactor = reserve.configuration.getReserveFactor();

    if (vars.reserveFactor == 0) {
      return;
    }

    //calculate the last principal variable debt
    vars.previousVariableDebt = scaledVariableDebt.rayMul(previousVariableBorrowIndex);

    //calculate the new total supply after accumulation of the index
    vars.currentVariableDebt = scaledVariableDebt.rayMul(newVariableBorrowIndex);

    //debt accrued is the sum of the current debt minus the sum of the debt at the last update
    vars.totalDebtAccrued = vars.currentVariableDebt - (vars.previousVariableDebt);

    vars.amountToMint = vars.totalDebtAccrued.percentMul(vars.reserveFactor);

    if (vars.amountToMint != 0) {
      IMToken(reserve.mTokenAddresses[0]).mintToTreasury(vars.amountToMint, newLiquidityIndices[0]);
    }
  }

  /**
   * @dev Updates the reserve indexes and the timestamp of the update
   * @param reserve The reserve reserve to be updated
   * @param scaledVariableDebt The scaled variable debt
   * @param liquidityIndices The last stored liquidity index
   * @param variableBorrowIndex The last stored variable borrow index
   * @param timestamp The timestamp of the action
   **/
  function _updateIndexes(
    DataTypes.ReserveData storage reserve,
    uint256 scaledVariableDebt,
    uint128[4] memory liquidityIndices,
    uint256 variableBorrowIndex,
    uint40 timestamp
  ) internal returns (uint256[4] memory, uint256) {
    
    uint256 newVariableBorrowIndex = variableBorrowIndex;

    uint256[4] memory newLiquidtyIndices;

    for (uint8 i = 0; i < newLiquidtyIndices.length; i++) {
      newLiquidtyIndices[i] = liquidityIndices[i];

      uint256 currentLiquidityRate = reserve.currentLiquidityRates[i];
      uint256 newLiquidityIndex = liquidityIndices[i];
      
      //only cumulating if there is any income being produced
      if (currentLiquidityRate > 0) {
        uint256 cumulatedLiquidityInterest = MathUtils.calculateLinearInterest(currentLiquidityRate, timestamp);
        newLiquidityIndex = cumulatedLiquidityInterest.rayMul(liquidityIndices[i]);
        require(newLiquidityIndex <= type(uint128).max, Errors.RL_LIQUIDITY_INDEX_OVERFLOW);

        reserve.liquidityIndices[i] = uint128(newLiquidityIndex);
        newLiquidtyIndices[i] = newLiquidityIndex;
      }
    }

    //as the liquidity rate might come only from stable rate loans, we need to ensure
    //that there is actual variable debt before accumulating
    if (scaledVariableDebt != 0 &&  (reserve.currentLiquidityRates[0] > 0 || reserve.currentLiquidityRates[1] > 0 || reserve.currentLiquidityRates[2] > 0 || reserve.currentLiquidityRates[3] > 0)) {
      uint256 cumulatedVariableBorrowInterest = MathUtils.calculateCompoundedInterest(
        reserve.currentVariableBorrowRate,
        timestamp
      );
      newVariableBorrowIndex = cumulatedVariableBorrowInterest.rayMul(variableBorrowIndex);
      require(newVariableBorrowIndex <= type(uint128).max, Errors.RL_VARIABLE_BORROW_INDEX_OVERFLOW);
      reserve.variableBorrowIndex = uint128(newVariableBorrowIndex);
    }
    

    //solium-disable-next-line
    reserve.lastUpdateTimestamp = uint40(block.timestamp);
    return (newLiquidtyIndices, newVariableBorrowIndex);
  }
}
