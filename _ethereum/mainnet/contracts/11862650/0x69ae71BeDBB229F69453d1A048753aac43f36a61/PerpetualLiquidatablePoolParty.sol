// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./PerpetualPositionManagerPoolParty.sol";

import "./FixedPoint.sol";
import "./PerpetualPositionManagerPoolPartyLib.sol";
import "./PerpetualLiquidatablePoolPartyLib.sol";

contract PerpetualLiquidatablePoolParty is PerpetualPositionManagerPoolParty {
  using FixedPoint for FixedPoint.Unsigned;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using FeePayerPoolPartyLib for FixedPoint.Unsigned;
  using PerpetualLiquidatablePoolPartyLib for PerpetualPositionManagerPoolParty.PositionData;
  using PerpetualLiquidatablePoolPartyLib for LiquidationData;

  enum Status {
    Uninitialized,
    PreDispute,
    PendingDispute,
    DisputeSucceeded,
    DisputeFailed
  }

  struct LiquidatableParams {
    uint256 liquidationLiveness;
    FixedPoint.Unsigned collateralRequirement;
    FixedPoint.Unsigned disputeBondPct;
    FixedPoint.Unsigned sponsorDisputeRewardPct;
    FixedPoint.Unsigned disputerDisputeRewardPct;
  }

  struct LiquidationData {
    address sponsor;
    address liquidator;
    Status state;
    uint256 liquidationTime;
    FixedPoint.Unsigned tokensOutstanding;
    FixedPoint.Unsigned lockedCollateral;
    FixedPoint.Unsigned liquidatedCollateral;
    FixedPoint.Unsigned rawUnitCollateral;
    address disputer;
    FixedPoint.Unsigned settlementPrice;
    FixedPoint.Unsigned finalFee;
  }

  struct ConstructorParams {
    PerpetualPositionManagerPoolParty.PositionManagerParams positionManagerParams;
    PerpetualPositionManagerPoolParty.Roles roles;
    LiquidatableParams liquidatableParams;
  }

  struct LiquidatableData {
    FixedPoint.Unsigned rawLiquidationCollateral;
    uint256 liquidationLiveness;
    FixedPoint.Unsigned collateralRequirement;
    FixedPoint.Unsigned disputeBondPct;
    FixedPoint.Unsigned sponsorDisputeRewardPct;
    FixedPoint.Unsigned disputerDisputeRewardPct;
  }

  struct RewardsData {
    FixedPoint.Unsigned payToSponsor;
    FixedPoint.Unsigned payToLiquidator;
    FixedPoint.Unsigned payToDisputer;
    FixedPoint.Unsigned paidToSponsor;
    FixedPoint.Unsigned paidToLiquidator;
    FixedPoint.Unsigned paidToDisputer;
  }

  mapping(address => LiquidationData[]) public liquidations;

  LiquidatableData public liquidatableData;

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
    Status indexed liquidationStatus,
    uint256 settlementPrice
  );

  modifier disputable(uint256 liquidationId, address sponsor) {
    _disputable(liquidationId, sponsor);
    _;
  }

  modifier withdrawable(uint256 liquidationId, address sponsor) {
    _withdrawable(liquidationId, sponsor);
    _;
  }

  constructor(ConstructorParams memory params)
    public
    PerpetualPositionManagerPoolParty(
      params.positionManagerParams,
      params.roles
    )
  {
    require(
      params.liquidatableParams.collateralRequirement.isGreaterThan(1),
      'CR is more than 100%'
    );
    require(
      params
        .liquidatableParams
        .sponsorDisputeRewardPct
        .add(params.liquidatableParams.disputerDisputeRewardPct)
        .isLessThan(1),
      'Rewards are more than 100%'
    );

    liquidatableData.liquidationLiveness = params
      .liquidatableParams
      .liquidationLiveness;
    liquidatableData.collateralRequirement = params
      .liquidatableParams
      .collateralRequirement;
    liquidatableData.disputeBondPct = params.liquidatableParams.disputeBondPct;
    liquidatableData.sponsorDisputeRewardPct = params
      .liquidatableParams
      .sponsorDisputeRewardPct;
    liquidatableData.disputerDisputeRewardPct = params
      .liquidatableParams
      .disputerDisputeRewardPct;
  }

  function createLiquidation(
    address sponsor,
    FixedPoint.Unsigned calldata minCollateralPerToken,
    FixedPoint.Unsigned calldata maxCollateralPerToken,
    FixedPoint.Unsigned calldata maxTokensToLiquidate,
    uint256 deadline
  )
    external
    fees()
    notEmergencyShutdown()
    nonReentrant()
    returns (
      uint256 liquidationId,
      FixedPoint.Unsigned memory tokensLiquidated,
      FixedPoint.Unsigned memory finalFeeBond
    )
  {
    PositionData storage positionToLiquidate = _getPositionData(sponsor);

    LiquidationData[] storage TokenSponsorLiquidations = liquidations[sponsor];

    FixedPoint.Unsigned memory finalFee = _computeFinalFees();

    uint256 actualTime = getCurrentTime();

    PerpetualLiquidatablePoolPartyLib.CreateLiquidationParams memory params =
      PerpetualLiquidatablePoolPartyLib.CreateLiquidationParams(
        minCollateralPerToken,
        maxCollateralPerToken,
        maxTokensToLiquidate,
        actualTime,
        deadline,
        finalFee,
        sponsor
      );


      PerpetualLiquidatablePoolPartyLib.CreateLiquidationReturnParams
        memory returnValues
    ;

    returnValues = positionToLiquidate.createLiquidation(
      globalPositionData,
      positionManagerData,
      liquidatableData,
      TokenSponsorLiquidations,
      params,
      feePayerData
    );

    return (
      returnValues.liquidationId,
      returnValues.tokensLiquidated,
      returnValues.finalFeeBond
    );
  }

  function dispute(uint256 liquidationId, address sponsor)
    external
    disputable(liquidationId, sponsor)
    fees()
    nonReentrant()
    returns (FixedPoint.Unsigned memory totalPaid)
  {
    LiquidationData storage disputedLiquidation =
      _getLiquidationData(sponsor, liquidationId);

    totalPaid = disputedLiquidation.dispute(
      liquidatableData,
      positionManagerData,
      feePayerData,
      liquidationId,
      sponsor
    );
  }

  function withdrawLiquidation(uint256 liquidationId, address sponsor)
    public
    withdrawable(liquidationId, sponsor)
    fees()
    nonReentrant()
    returns (RewardsData memory)
  {
    LiquidationData storage liquidation =
      _getLiquidationData(sponsor, liquidationId);

    RewardsData memory rewardsData =
      liquidation.withdrawLiquidation(
        liquidatableData,
        positionManagerData,
        feePayerData,
        liquidationId,
        sponsor
      );

    return rewardsData;
  }

  function deleteLiquidation(uint256 liquidationId, address sponsor)
    external
    onlyThisContract
  {
    delete liquidations[sponsor][liquidationId];
  }

  function _pfc() internal view override returns (FixedPoint.Unsigned memory) {
    return
      super._pfc().add(
        liquidatableData.rawLiquidationCollateral.getFeeAdjustedCollateral(
          feePayerData.cumulativeFeeMultiplier
        )
      );
  }

  function _getLiquidationData(address sponsor, uint256 liquidationId)
    internal
    view
    returns (LiquidationData storage liquidation)
  {
    LiquidationData[] storage liquidationArray = liquidations[sponsor];

    require(
      liquidationId < liquidationArray.length &&
        liquidationArray[liquidationId].state != Status.Uninitialized,
      'Invalid liquidation ID'
    );
    return liquidationArray[liquidationId];
  }

  function _getLiquidationExpiry(LiquidationData storage liquidation)
    internal
    view
    returns (uint256)
  {
    return
      liquidation.liquidationTime.add(liquidatableData.liquidationLiveness);
  }

  function _disputable(uint256 liquidationId, address sponsor) internal view {
    LiquidationData storage liquidation =
      _getLiquidationData(sponsor, liquidationId);
    require(
      (getCurrentTime() < _getLiquidationExpiry(liquidation)) &&
        (liquidation.state == Status.PreDispute),
      'Liquidation not disputable'
    );
  }

  function _withdrawable(uint256 liquidationId, address sponsor) internal view {
    LiquidationData storage liquidation =
      _getLiquidationData(sponsor, liquidationId);
    Status state = liquidation.state;

    require(
      (state > Status.PreDispute) ||
        ((_getLiquidationExpiry(liquidation) <= getCurrentTime()) &&
          (state == Status.PreDispute)),
      'Liquidation not withdrawable'
    );
  }
}
