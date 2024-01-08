// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./MintableBurnableIERC20.sol";
import "./SafeMath.sol";
import "./FixedPoint.sol";
import "./SafeERC20.sol";
import "./FeePayerPartyLib.sol";
import "./SelfMintingPerpetualPositionManagerMultiPartyLib.sol";
import "./FeePayerParty.sol";
import "./SelfMintingPerpetualLiquidatableMultiParty.sol";
import "./SelfMintingPerpetualPositionManagerMultiParty.sol";

/** @title A library for SelfMintingPerpetualLiquidatableMultiParty contract
 */
library SelfMintingPerpetualLiquidatableMultiPartyLib {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using SafeERC20 for MintableBurnableIERC20;
  using FixedPoint for FixedPoint.Unsigned;
  using SelfMintingPerpetualPositionManagerMultiPartyLib for SelfMintingPerpetualPositionManagerMultiParty.PositionData;
  using FeePayerPartyLib for FixedPoint.Unsigned;
  using SelfMintingPerpetualPositionManagerMultiPartyLib for SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData;
  using SelfMintingPerpetualLiquidatableMultiPartyLib for SelfMintingPerpetualLiquidatableMultiParty.LiquidationData;
  using SelfMintingPerpetualPositionManagerMultiPartyLib for FixedPoint.Unsigned;

  struct CreateLiquidationParams {
    FixedPoint.Unsigned minCollateralPerToken;
    FixedPoint.Unsigned maxCollateralPerToken;
    FixedPoint.Unsigned maxTokensToLiquidate;
    uint256 actualTime;
    uint256 deadline;
    FixedPoint.Unsigned finalFee;
    address sponsor;
  }

  struct CreateLiquidationCollateral {
    FixedPoint.Unsigned startCollateral;
    FixedPoint.Unsigned startCollateralNetOfWithdrawal;
    FixedPoint.Unsigned tokensLiquidated;
    FixedPoint.Unsigned finalFeeBond;
    address sponsor;
  }

  struct CreateLiquidationReturnParams {
    uint256 liquidationId;
    FixedPoint.Unsigned lockedCollateral;
    FixedPoint.Unsigned liquidatedCollateral;
    FixedPoint.Unsigned tokensLiquidated;
    FixedPoint.Unsigned finalFeeBond;
  }

  // Stores the parameters for a settlement after liquidation process
  struct SettleParams {
    FixedPoint.Unsigned feeAttenuation;
    FixedPoint.Unsigned settlementPrice;
    FixedPoint.Unsigned tokenRedemptionValue;
    FixedPoint.Unsigned collateral;
    FixedPoint.Unsigned disputerDisputeReward;
    FixedPoint.Unsigned sponsorDisputeReward;
    FixedPoint.Unsigned disputeBondAmount;
    FixedPoint.Unsigned finalFee;
    FixedPoint.Unsigned withdrawalAmount;
  }

  //----------------------------------------
  // Events
  //----------------------------------------

  event LiquidationCreated(
    address indexed sponsor,
    address indexed liquidator,
    uint256 indexed liquidationId,
    uint256 tokensOutstanding,
    uint256 lockedCollateral,
    uint256 liquidatedCollateral,
    uint256 liquidationTime
  );
  event LiquidationDisputed(
    address indexed sponsor,
    address indexed liquidator,
    address indexed disputer,
    uint256 liquidationId,
    uint256 disputeBondAmount
  );

  event DisputeSettled(
    address indexed caller,
    address indexed sponsor,
    address indexed liquidator,
    address disputer,
    uint256 liquidationId,
    bool disputeSucceeded
  );

  event LiquidationWithdrawn(
    address indexed caller,
    uint256 paidToLiquidator,
    uint256 paidToDisputer,
    uint256 paidToSponsor,
    SelfMintingPerpetualLiquidatableMultiParty.Status indexed liquidationStatus,
    uint256 settlementPrice
  );

  //----------------------------------------
  // External functions
  //----------------------------------------

  /**
   * @notice A function used by createLiquidation from SelfMintingPerpetualLiquidatableMultiParty contract
   * to return all necessary parameters for a liquidation and perform the liquidation
   * @param positionToLiquidate The position to be liquidated
   * @param globalPositionData Global data for the position that will be liquidated fetched from storage
   * @param positionManagerData Specific position data fetched from storage
   * @param liquidatableData Data for the liquidation fetched from storage
   * @param liquidations Array containing actual existing liquidations
   * @param params Parameters for the liquidation process
   * @param feePayerData Fees and distribution data fetched from storage
   */
  function createLiquidation(
    SelfMintingPerpetualPositionManagerMultiParty.PositionData
      storage positionToLiquidate,
    SelfMintingPerpetualPositionManagerMultiParty.GlobalPositionData
      storage globalPositionData,
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
      storage positionManagerData,
    SelfMintingPerpetualLiquidatableMultiParty.LiquidatableData
      storage liquidatableData,
    SelfMintingPerpetualLiquidatableMultiParty.LiquidationData[]
      storage liquidations,
    CreateLiquidationParams memory params,
    FeePayerParty.FeePayerData storage feePayerData
  ) external returns (CreateLiquidationReturnParams memory returnValues) {
    FixedPoint.Unsigned memory startCollateral;
    FixedPoint.Unsigned memory startCollateralNetOfWithdrawal;

    (
      startCollateral,
      startCollateralNetOfWithdrawal,
      returnValues.tokensLiquidated
    ) = calculateNetLiquidation(positionToLiquidate, params, feePayerData);

    {
      FixedPoint.Unsigned memory startTokens =
        positionToLiquidate.tokensOutstanding;

      require(
        params.maxCollateralPerToken.mul(startTokens).isGreaterThanOrEqual(
          startCollateralNetOfWithdrawal
        ),
        'CR is more than max liq. price'
      );

      require(
        params.minCollateralPerToken.mul(startTokens).isLessThanOrEqual(
          startCollateralNetOfWithdrawal
        ),
        'CR is less than min liq. price'
      );
    }
    {
      returnValues.finalFeeBond = params.finalFee;

      CreateLiquidationCollateral memory liquidationCollateral =
        CreateLiquidationCollateral(
          startCollateral,
          startCollateralNetOfWithdrawal,
          returnValues.tokensLiquidated,
          returnValues.finalFeeBond,
          params.sponsor
        );

      (
        returnValues.lockedCollateral,
        returnValues.liquidatedCollateral
      ) = liquidateCollateral(
        positionToLiquidate,
        globalPositionData,
        positionManagerData,
        liquidatableData,
        feePayerData,
        liquidationCollateral
      );

      returnValues.liquidationId = liquidations.length;
      liquidations.push(
        SelfMintingPerpetualLiquidatableMultiParty.LiquidationData({
          sponsor: params.sponsor,
          liquidator: msg.sender,
          state: SelfMintingPerpetualLiquidatableMultiParty.Status.PreDispute,
          liquidationTime: params.actualTime,
          tokensOutstanding: returnValues.tokensLiquidated,
          lockedCollateral: returnValues.lockedCollateral,
          liquidatedCollateral: returnValues.liquidatedCollateral,
          rawUnitCollateral: FixedPoint
            .fromUnscaledUint(1)
            .convertToRawCollateral(feePayerData.cumulativeFeeMultiplier),
          disputer: address(0),
          settlementPrice: FixedPoint.fromUnscaledUint(0),
          finalFee: returnValues.finalFeeBond
        })
      );
    }

    {
      FixedPoint.Unsigned memory griefingThreshold =
        positionManagerData.minSponsorTokens;
      if (
        positionToLiquidate.withdrawalRequestPassTimestamp > 0 &&
        positionToLiquidate.withdrawalRequestPassTimestamp >
        params.actualTime &&
        returnValues.tokensLiquidated.isGreaterThanOrEqual(griefingThreshold)
      ) {
        positionToLiquidate.withdrawalRequestPassTimestamp = params
          .actualTime
          .add(positionManagerData.withdrawalLiveness);
      }
    }
    emit LiquidationCreated(
      params.sponsor,
      msg.sender,
      returnValues.liquidationId,
      returnValues.tokensLiquidated.rawValue,
      returnValues.lockedCollateral.rawValue,
      returnValues.liquidatedCollateral.rawValue,
      params.actualTime
    );

    burnAndLiquidateFee(
      positionManagerData,
      feePayerData,
      returnValues.tokensLiquidated,
      returnValues.finalFeeBond
    );
  }

  /**
   * @notice A function used by dispute function from SelfMintingPerpetualLiquidatableMultiParty contract
   * to return all necessary parameters for a dispute and perform the dispute
   * @param disputedLiquidation The liquidation to be disputed fetched from storage
   * @param liquidatableData Data for the liquidation fetched from storage
   * @param positionManagerData Data for specific position of a sponsor fetched from storage
   * @param feePayerData Fees and distribution data fetched from storage
   * @param liquidationId The id of the liquidation to be disputed
   * @param sponsor The address of the token sponsor on which a liqudation was performed
   */
  function dispute(
    SelfMintingPerpetualLiquidatableMultiParty.LiquidationData
      storage disputedLiquidation,
    SelfMintingPerpetualLiquidatableMultiParty.LiquidatableData
      storage liquidatableData,
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
      storage positionManagerData,
    FeePayerParty.FeePayerData storage feePayerData,
    uint256 liquidationId,
    address sponsor
  ) external returns (FixedPoint.Unsigned memory totalPaid) {
    FixedPoint.Unsigned memory disputeBondAmount =
      disputedLiquidation
        .lockedCollateral
        .mul(liquidatableData.disputeBondPct)
        .mul(
        disputedLiquidation.rawUnitCollateral.getFeeAdjustedCollateral(
          feePayerData.cumulativeFeeMultiplier
        )
      );
    liquidatableData.rawLiquidationCollateral.addCollateral(
      disputeBondAmount,
      feePayerData.cumulativeFeeMultiplier
    );

    disputedLiquidation.state = SelfMintingPerpetualLiquidatableMultiParty
      .Status
      .PendingDispute;
    disputedLiquidation.disputer = msg.sender;

    positionManagerData.requestOraclePrice(
      disputedLiquidation.liquidationTime,
      feePayerData
    );

    emit LiquidationDisputed(
      sponsor,
      disputedLiquidation.liquidator,
      msg.sender,
      liquidationId,
      disputeBondAmount.rawValue
    );

    totalPaid = disputeBondAmount.add(disputedLiquidation.finalFee);

    FeePayerParty(address(this)).payFinalFees(
      msg.sender,
      disputedLiquidation.finalFee
    );

    feePayerData.collateralCurrency.safeTransferFrom(
      msg.sender,
      address(this),
      disputeBondAmount.rawValue
    );
  }

  /**
   * @notice A function used by withdrawLiquidation function from SelfMintingPerpetualLiquidatableMultiParty contract
   * to withdraw any proceeds after a successfull liquidation on a token sponsor position
   * @param liquidation The liquidation for which proceeds will be withdrawn fetched from storage
   * @param liquidatableData Data for the liquidation fetched from storage
   * @param positionManagerData Data for specific position of a sponsor fetched from storage
   * @param feePayerData Fees and distribution data fetched from storage
   * @param liquidationId The id of the liquidation for which to withdraw proceeds
   * @param sponsor The address of the token sponsor on which a liqudation was performed
   */
  function withdrawLiquidation(
    SelfMintingPerpetualLiquidatableMultiParty.LiquidationData
      storage liquidation,
    SelfMintingPerpetualLiquidatableMultiParty.LiquidatableData
      storage liquidatableData,
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
      storage positionManagerData,
    FeePayerParty.FeePayerData storage feePayerData,
    uint256 liquidationId,
    address sponsor
  )
    external
    returns (
      SelfMintingPerpetualLiquidatableMultiParty.RewardsData memory rewards
    )
  {
    liquidation._settle(
      positionManagerData,
      liquidatableData,
      feePayerData,
      liquidationId,
      sponsor
    );

    SettleParams memory settleParams;

    settleParams.feeAttenuation = liquidation
      .rawUnitCollateral
      .getFeeAdjustedCollateral(feePayerData.cumulativeFeeMultiplier);
    settleParams.settlementPrice = liquidation.settlementPrice;
    settleParams.tokenRedemptionValue = liquidation
      .tokensOutstanding
      .mul(settleParams.settlementPrice)
      .mul(settleParams.feeAttenuation);
    settleParams.collateral = liquidation.lockedCollateral.mul(
      settleParams.feeAttenuation
    );
    settleParams.disputerDisputeReward = liquidatableData
      .disputerDisputeRewardPct
      .mul(settleParams.tokenRedemptionValue);
    settleParams.sponsorDisputeReward = liquidatableData
      .sponsorDisputeRewardPct
      .mul(settleParams.tokenRedemptionValue);
    settleParams.disputeBondAmount = settleParams.collateral.mul(
      liquidatableData.disputeBondPct
    );
    settleParams.finalFee = liquidation.finalFee.mul(
      settleParams.feeAttenuation
    );

    if (
      liquidation.state ==
      SelfMintingPerpetualLiquidatableMultiParty.Status.DisputeSucceeded
    ) {
      rewards.payToDisputer = settleParams
        .disputerDisputeReward
        .add(settleParams.disputeBondAmount)
        .add(settleParams.finalFee);

      rewards.payToSponsor = settleParams.sponsorDisputeReward.add(
        settleParams.collateral.sub(settleParams.tokenRedemptionValue)
      );

      rewards.payToLiquidator = settleParams
        .tokenRedemptionValue
        .sub(settleParams.sponsorDisputeReward)
        .sub(settleParams.disputerDisputeReward);

      rewards.paidToLiquidator = liquidatableData
        .rawLiquidationCollateral
        .removeCollateral(
        rewards.payToLiquidator,
        feePayerData.cumulativeFeeMultiplier
      );
      rewards.paidToSponsor = liquidatableData
        .rawLiquidationCollateral
        .removeCollateral(
        rewards.payToSponsor,
        feePayerData.cumulativeFeeMultiplier
      );
      rewards.paidToDisputer = liquidatableData
        .rawLiquidationCollateral
        .removeCollateral(
        rewards.payToDisputer,
        feePayerData.cumulativeFeeMultiplier
      );

      feePayerData.collateralCurrency.safeTransfer(
        liquidation.disputer,
        rewards.paidToDisputer.rawValue
      );
      feePayerData.collateralCurrency.safeTransfer(
        liquidation.liquidator,
        rewards.paidToLiquidator.rawValue
      );
      feePayerData.collateralCurrency.safeTransfer(
        liquidation.sponsor,
        rewards.paidToSponsor.rawValue
      );
    } else if (
      liquidation.state ==
      SelfMintingPerpetualLiquidatableMultiParty.Status.DisputeFailed
    ) {
      rewards.payToLiquidator = settleParams
        .collateral
        .add(settleParams.disputeBondAmount)
        .add(settleParams.finalFee);

      rewards.paidToLiquidator = liquidatableData
        .rawLiquidationCollateral
        .removeCollateral(
        rewards.payToLiquidator,
        feePayerData.cumulativeFeeMultiplier
      );

      feePayerData.collateralCurrency.safeTransfer(
        liquidation.liquidator,
        rewards.paidToLiquidator.rawValue
      );
    } else if (
      liquidation.state ==
      SelfMintingPerpetualLiquidatableMultiParty.Status.PreDispute
    ) {
      rewards.payToLiquidator = settleParams.collateral.add(
        settleParams.finalFee
      );

      rewards.paidToLiquidator = liquidatableData
        .rawLiquidationCollateral
        .removeCollateral(
        rewards.payToLiquidator,
        feePayerData.cumulativeFeeMultiplier
      );

      feePayerData.collateralCurrency.safeTransfer(
        liquidation.liquidator,
        rewards.paidToLiquidator.rawValue
      );
    }

    emit LiquidationWithdrawn(
      msg.sender,
      rewards.paidToLiquidator.rawValue,
      rewards.paidToDisputer.rawValue,
      rewards.paidToSponsor.rawValue,
      liquidation.state,
      settleParams.settlementPrice.rawValue
    );

    SelfMintingPerpetualLiquidatableMultiParty(address(this)).deleteLiquidation(
      liquidationId,
      sponsor
    );

    return rewards;
  }

  //----------------------------------------
  // Internal functions
  //----------------------------------------
  /**
   * @notice Calculate the amount of collateral received after liquidation
   * @param positionToLiquidate The position which will be liquidated fetched from storage
   * @param globalPositionData Data for the global position fetched from storage
   * @param positionManagerData Data for specific position of a sponsor fetched from storage
   * @param liquidatableData Data for the liquidation fetched from storage
   * @param feePayerData Fees and distribution data fetched from storage
   * @param liquidationCollateralParams Collateral parameters passed to a liquidation process fetched from storage
   */
  function liquidateCollateral(
    SelfMintingPerpetualPositionManagerMultiParty.PositionData
      storage positionToLiquidate,
    SelfMintingPerpetualPositionManagerMultiParty.GlobalPositionData
      storage globalPositionData,
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
      storage positionManagerData,
    SelfMintingPerpetualLiquidatableMultiParty.LiquidatableData
      storage liquidatableData,
    FeePayerParty.FeePayerData storage feePayerData,
    CreateLiquidationCollateral memory liquidationCollateralParams
  )
    internal
    returns (
      FixedPoint.Unsigned memory lockedCollateral,
      FixedPoint.Unsigned memory liquidatedCollateral
    )
  {
    {
      FixedPoint.Unsigned memory ratio =
        liquidationCollateralParams.tokensLiquidated.div(
          positionToLiquidate.tokensOutstanding
        );

      lockedCollateral = liquidationCollateralParams.startCollateral.mul(ratio);

      liquidatedCollateral = liquidationCollateralParams
        .startCollateralNetOfWithdrawal
        .mul(ratio);

      FixedPoint.Unsigned memory withdrawalAmountToRemove =
        positionToLiquidate.withdrawalRequestAmount.mul(ratio);

      positionToLiquidate.reduceSponsorPosition(
        globalPositionData,
        positionManagerData,
        liquidationCollateralParams.tokensLiquidated,
        lockedCollateral,
        withdrawalAmountToRemove,
        feePayerData,
        liquidationCollateralParams.sponsor
      );
    }

    liquidatableData.rawLiquidationCollateral.addCollateral(
      lockedCollateral.add(liquidationCollateralParams.finalFeeBond),
      feePayerData.cumulativeFeeMultiplier
    );
  }

  /**
   * @notice Burn an amount of synthetic tokens and post liquidate fee
   * @param positionManagerData Data for specific position of a sponsor fetched from storage
   * @param feePayerData Fees and distribution data fetched from storage
   * @param tokensLiquidated The amount of synthetic tokens to be used for liquidation
   * @param finalFeeBond The amount of fee posted as a bond when triggering liquidation
   */
  function burnAndLiquidateFee(
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
      storage positionManagerData,
    FeePayerParty.FeePayerData storage feePayerData,
    FixedPoint.Unsigned memory tokensLiquidated,
    FixedPoint.Unsigned memory finalFeeBond
  ) internal {
    positionManagerData.tokenCurrency.safeTransferFrom(
      msg.sender,
      address(this),
      tokensLiquidated.rawValue
    );
    positionManagerData.tokenCurrency.burn(tokensLiquidated.rawValue);

    feePayerData.collateralCurrency.safeTransferFrom(
      msg.sender,
      address(this),
      finalFeeBond.rawValue
    );
  }

  /**
   * @notice Settle a liquidation
   * @param liquidation The liquidation performed fetched from storage
   * @param positionManagerData Data for a certain tokens sponsor position fetched from storage
   * @param liquidatableData Data used for the liquidation fetched from storage
   * @param feePayerData Fees and distribution data fetched from storage
   * @param liquidationId The id of the liquidation performed
   * @param sponsor The address of the token sponsor on which a liquidation was performed
   */
  function _settle(
    SelfMintingPerpetualLiquidatableMultiParty.LiquidationData
      storage liquidation,
    SelfMintingPerpetualPositionManagerMultiParty.PositionManagerData
      storage positionManagerData,
    SelfMintingPerpetualLiquidatableMultiParty.LiquidatableData
      storage liquidatableData,
    FeePayerParty.FeePayerData storage feePayerData,
    uint256 liquidationId,
    address sponsor
  ) internal {
    if (
      liquidation.state !=
      SelfMintingPerpetualLiquidatableMultiParty.Status.PendingDispute
    ) {
      return;
    }

    FixedPoint.Unsigned memory oraclePrice =
      positionManagerData.getOraclePrice(
        liquidation.liquidationTime,
        feePayerData
      );

    liquidation.settlementPrice = oraclePrice.decimalsScalingFactor(
      feePayerData
    );

    FixedPoint.Unsigned memory tokenRedemptionValue =
      liquidation.tokensOutstanding.mul(liquidation.settlementPrice);

    FixedPoint.Unsigned memory requiredCollateral =
      tokenRedemptionValue.mul(liquidatableData.collateralRequirement);

    bool disputeSucceeded =
      liquidation.liquidatedCollateral.isGreaterThanOrEqual(requiredCollateral);
    liquidation.state = disputeSucceeded
      ? SelfMintingPerpetualLiquidatableMultiParty.Status.DisputeSucceeded
      : SelfMintingPerpetualLiquidatableMultiParty.Status.DisputeFailed;

    emit DisputeSettled(
      msg.sender,
      sponsor,
      liquidation.liquidator,
      liquidation.disputer,
      liquidationId,
      disputeSucceeded
    );
  }

  /**
   * @notice Calculate the net output of a liquidation
   * @param positionToLiquidate Position to be liquidated fetched from storage
   * @param params Parameters to be passed to the liquidation creation
   * @param feePayerData Fees and distribution data fetched from storage
   */
  function calculateNetLiquidation(
    SelfMintingPerpetualPositionManagerMultiParty.PositionData
      storage positionToLiquidate,
    CreateLiquidationParams memory params,
    FeePayerParty.FeePayerData storage feePayerData
  )
    internal
    view
    returns (
      FixedPoint.Unsigned memory startCollateral,
      FixedPoint.Unsigned memory startCollateralNetOfWithdrawal,
      FixedPoint.Unsigned memory tokensLiquidated
    )
  {
    tokensLiquidated = FixedPoint.min(
      params.maxTokensToLiquidate,
      positionToLiquidate.tokensOutstanding
    );
    require(tokensLiquidated.isGreaterThan(0), 'Liquidating 0 tokens');

    require(params.actualTime <= params.deadline, 'Mined after deadline');

    startCollateral = positionToLiquidate
      .rawCollateral
      .getFeeAdjustedCollateral(feePayerData.cumulativeFeeMultiplier);
    startCollateralNetOfWithdrawal = FixedPoint.fromUnscaledUint(0);

    if (
      positionToLiquidate.withdrawalRequestAmount.isLessThanOrEqual(
        startCollateral
      )
    ) {
      startCollateralNetOfWithdrawal = startCollateral.sub(
        positionToLiquidate.withdrawalRequestAmount
      );
    }
  }
}
