// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "./VirtualAAVEStakedToken.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

/**
 * @title LyraSafetyModule
 * @notice Contract to stake Lyra token, tokenize the position and get rewards, inheriting from AAVE StakedTokenV3
 * @author Lyra
 **/
contract LyraSafetyModuleMigration is VirtualAAVEStakedToken {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  string internal constant NAME = "Staked Lyra";
  string internal constant SYMBOL = "stkLYRA";
  uint8 internal constant DECIMALS = 18;

  constructor(
    IERC20 stakedToken,
    IERC20 rewardToken,
    uint256 cooldownSeconds,
    uint256 unstakeWindow,
    address rewardsVault,
    address emissionManager,
    uint128 distributionDuration
  )
    public
    VirtualAAVEStakedToken(
      stakedToken,
      rewardToken,
      cooldownSeconds,
      unstakeWindow,
      rewardsVault,
      emissionManager,
      distributionDuration,
      NAME,
      SYMBOL,
      DECIMALS,
      address(0)
    )
  {}

  function stake(address onBehalfOf, uint256 amount) public override {
    super.stake(onBehalfOf, amount);
  }

  function redeem(address to, uint256 amount) public override {
    require(amount != 0, "INVALID_ZERO_AMOUNT");

    //solium-disable-next-line
    uint256 balanceOfMessageSender = balanceOf(msg.sender);

    uint256 amountToRedeem = (amount > balanceOfMessageSender) ? balanceOfMessageSender : amount;

    _updateCurrentUnclaimedRewards(msg.sender, balanceOfMessageSender, true);

    _burn(msg.sender, amountToRedeem);

    if (balanceOfMessageSender.sub(amountToRedeem) == 0) {
      stakersCooldowns[msg.sender] = 0;
    }

    IERC20(STAKED_TOKEN).safeTransfer(to, amountToRedeem);

    emit Redeem(msg.sender, to, amountToRedeem);
  }

  function cooldown() public override {
    super.cooldown();
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    super.transfer(recipient, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    super.transferFrom(sender, recipient, amount);
    return true;
  }
}
