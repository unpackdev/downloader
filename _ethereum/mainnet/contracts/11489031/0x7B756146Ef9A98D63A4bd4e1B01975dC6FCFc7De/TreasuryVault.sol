// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./IVault.sol";

contract TreasuryVault is IVault {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event LPRewardDistributed(uint256 amount);
  event TreasuryDeposit(uint256 amount);

  address public tdao;
  address public rewardsVault;
  address public treasury;

  uint256 public rewardFee = 9000;
  uint256 public constant BASE = 10000;

  constructor(
    address _tdao,
    address _RewardsVault,
    address _treasuryAddress
  ) public {
    tdao = _tdao;
    rewardsVault = _RewardsVault;
    treasury = _treasuryAddress;
  }

  function update(uint256 amount) external override {
    amount; // Silence warning;

    uint256 _balance = IERC20(tdao).balanceOf(address(this));

    if (_balance < 100) {
      return;
    }

    uint256 rewardShare = _balance.mul(rewardFee).div(BASE);
    uint256 treasuryShare = _balance.sub(rewardShare);

    IERC20(tdao).safeTransfer(rewardsVault, rewardShare);
    IERC20(tdao).safeTransfer(treasury, treasuryShare);

    IVault(rewardsVault).update(rewardShare);

    emit LPRewardDistributed(rewardShare);
    emit TreasuryDeposit(treasuryShare);
  }

  function sendERC20ToTreasury(address token) external {
    IERC20(token).safeTransfer(
      treasury,
      IERC20(token).balanceOf(address(this))
    );
  }
}
