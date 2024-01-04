// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./FixedPoint.sol";
import "./MultiRole.sol";
import "./Withdrawable.sol";
import "./Testable.sol";
import "./StoreInterface.sol";

contract Store is StoreInterface, Withdrawable, Testable {
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Unsigned;
  using FixedPoint for uint256;
  using SafeERC20 for IERC20;

  enum Roles {Owner, Withdrawer}

  FixedPoint.Unsigned public fixedOracleFeePerSecondPerPfc;
  FixedPoint.Unsigned public weeklyDelayFeePerSecondPerPfc;

  mapping(address => FixedPoint.Unsigned) public finalFees;
  uint256 public constant SECONDS_PER_WEEK = 604800;

  event NewFixedOracleFeePerSecondPerPfc(FixedPoint.Unsigned newOracleFee);
  event NewWeeklyDelayFeePerSecondPerPfc(
    FixedPoint.Unsigned newWeeklyDelayFeePerSecondPerPfc
  );
  event NewFinalFee(FixedPoint.Unsigned newFinalFee);

  constructor(
    FixedPoint.Unsigned memory _fixedOracleFeePerSecondPerPfc,
    FixedPoint.Unsigned memory _weeklyDelayFeePerSecondPerPfc,
    address _timerAddress
  ) public Testable(_timerAddress) {
    _createExclusiveRole(
      uint256(Roles.Owner),
      uint256(Roles.Owner),
      msg.sender
    );
    _createWithdrawRole(
      uint256(Roles.Withdrawer),
      uint256(Roles.Owner),
      msg.sender
    );
    setFixedOracleFeePerSecondPerPfc(_fixedOracleFeePerSecondPerPfc);
    setWeeklyDelayFeePerSecondPerPfc(_weeklyDelayFeePerSecondPerPfc);
  }

  function payOracleFees() external payable override {
    require(msg.value > 0, "Value sent can't be zero");
  }

  function payOracleFeesErc20(
    address erc20Address,
    FixedPoint.Unsigned calldata amount
  ) external override {
    IERC20 erc20 = IERC20(erc20Address);
    require(amount.isGreaterThan(0), "Amount sent can't be zero");
    erc20.safeTransferFrom(msg.sender, address(this), amount.rawValue);
  }

  function computeRegularFee(
    uint256 startTime,
    uint256 endTime,
    FixedPoint.Unsigned calldata pfc
  )
    external
    view
    override
    returns (
      FixedPoint.Unsigned memory regularFee,
      FixedPoint.Unsigned memory latePenalty
    )
  {
    uint256 timeDiff = endTime.sub(startTime);

    regularFee = pfc.mul(timeDiff).mul(fixedOracleFeePerSecondPerPfc);

    uint256 paymentDelay = getCurrentTime().sub(startTime);

    FixedPoint.Unsigned memory penaltyPercentagePerSecond =
      weeklyDelayFeePerSecondPerPfc.mul(paymentDelay.div(SECONDS_PER_WEEK));

    latePenalty = pfc.mul(timeDiff).mul(penaltyPercentagePerSecond);
  }

  function computeFinalFee(address currency)
    external
    view
    override
    returns (FixedPoint.Unsigned memory)
  {
    return finalFees[currency];
  }

  function setFixedOracleFeePerSecondPerPfc(
    FixedPoint.Unsigned memory newFixedOracleFeePerSecondPerPfc
  ) public onlyRoleHolder(uint256(Roles.Owner)) {
    require(
      newFixedOracleFeePerSecondPerPfc.isLessThan(1),
      'Fee must be < 100% per second.'
    );
    fixedOracleFeePerSecondPerPfc = newFixedOracleFeePerSecondPerPfc;
    emit NewFixedOracleFeePerSecondPerPfc(newFixedOracleFeePerSecondPerPfc);
  }

  function setWeeklyDelayFeePerSecondPerPfc(
    FixedPoint.Unsigned memory newWeeklyDelayFeePerSecondPerPfc
  ) public onlyRoleHolder(uint256(Roles.Owner)) {
    require(
      newWeeklyDelayFeePerSecondPerPfc.isLessThan(1),
      'weekly delay fee must be < 100%'
    );
    weeklyDelayFeePerSecondPerPfc = newWeeklyDelayFeePerSecondPerPfc;
    emit NewWeeklyDelayFeePerSecondPerPfc(newWeeklyDelayFeePerSecondPerPfc);
  }

  function setFinalFee(address currency, FixedPoint.Unsigned memory newFinalFee)
    public
    onlyRoleHolder(uint256(Roles.Owner))
  {
    finalFees[currency] = newFinalFee;
    emit NewFinalFee(newFinalFee);
  }
}
