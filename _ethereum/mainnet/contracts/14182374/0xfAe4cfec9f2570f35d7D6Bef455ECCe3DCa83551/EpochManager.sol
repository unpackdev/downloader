// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IRewarder.sol";
import "./AmmRewards.sol";
import "./RewardsManager.sol";

contract EpochManager is Ownable {
  using SafeERC20 for IERC20;

  IERC20 private rewardsToken;
  address private rewardsContract;
  address private rewardsManagerContract;

  struct PoolAllocPoint {
    uint256 pid;
    uint256 allocPoint;
    IRewarder rewarder;
    bool overwrite;
  }

  event EpochReleased(uint256[] pids, uint256 amount);
  event AllocPointsSet(uint256[] pids, uint256 amount);

  constructor(
    IERC20 _rewardsToken,
    address _rewardsContract,
    address _rewardsManagerContract
  ) public {
    rewardsToken = _rewardsToken;
    rewardsContract = _rewardsContract;
    rewardsManagerContract = _rewardsManagerContract;
  }

  function doOpsEpochRewards(
    uint256[] calldata pids,
    PoolAllocPoint[] memory poolAllocPoints,
    uint256 amount,
    address origOwner
  ) external onlyOwner {
    require(
      AmmRewards(rewardsContract).poolLength() > 0,
      'AmmRewards pools not set'
    );

    for (uint256 i = 0; i < poolAllocPoints.length; i++) {
      AmmRewards(rewardsContract).massUpdatePools(pids);
      AmmRewards(rewardsContract).set(
        poolAllocPoints[i].pid,
        poolAllocPoints[i].allocPoint,
        poolAllocPoints[i].rewarder,
        poolAllocPoints[i].overwrite
      );
    }

    if (amount > 0 && rewardsManagerContract != address(0)) {
      IERC20(rewardsToken).safeApprove(rewardsManagerContract, amount);
      RewardsManager(rewardsManagerContract).releaseEpochRewards(amount);

      emit EpochReleased(pids, amount);
    }

    // Transfer contract ownerships back to multisig
    if (AmmRewards(rewardsContract).owner() != origOwner) {
      AmmRewards(rewardsContract).transferOwnership(origOwner);
    }
    if (rewardsManagerContract != address(0) && RewardsManager(rewardsManagerContract).owner() != origOwner) {
      RewardsManager(rewardsManagerContract).transferOwnership(origOwner);
    }

    emit AllocPointsSet(pids, amount);
  }

  /****************************************
   *            ADMIN FUNCTIONS           *
   ****************************************/
  function setRewardsTokenContract(IERC20 _rewardsTokenContract)
    external
    onlyOwner
  {
    require(
      address(_rewardsTokenContract) != address(0),
      'Rewards Token contract cannot be empty!'
    );
    rewardsToken = _rewardsTokenContract;
  }

  function setRewardsContract(address _rewardsContract) external onlyOwner {
    require(
      _rewardsContract != address(0),
      'Rewards contract cannot be empty!'
    );
    rewardsContract = _rewardsContract;
  }

  function setRewardsManagerContract(address _rewardsManagerContract)
    external
    onlyOwner
  {
    rewardsManagerContract = _rewardsManagerContract;
  }

  /****************************************
   *            VIEW FUNCTIONS            *
   ****************************************/

  function getRewardsTokenContract() external view returns (IERC20) {
    return rewardsToken;
  }

  function getRewardsContract() external view returns (address) {
    return rewardsContract;
  }

  function getRewardsManagerContract() external view returns (address) {
    return rewardsManagerContract;
  }
}
