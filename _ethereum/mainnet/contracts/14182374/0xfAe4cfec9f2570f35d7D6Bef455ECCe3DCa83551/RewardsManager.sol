// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IRewards.sol";
import "./AmmRewards.sol";
import "./HaloHalo.sol";

contract RewardsManager is Ownable {
  using SafeERC20 for IERC20;
  using SafeERC20 for HaloHalo;

  IERC20 public halo;
  // in basis points
  uint256 private vestingRatio;
  address private rewardsContract;
  address private haloHaloContract;

  using SafeMath for uint256;
  uint256 public constant BASIS_POINTS = 10**4;

  constructor(
    uint256 _initialVestingRatio, //in BASIS_POINTS, multiplied by 10^4
    address _rewardsContract,
    address _haloHaloContract,
    IERC20 _halo
  ) public {
    vestingRatio = _initialVestingRatio;
    rewardsContract = _rewardsContract;
    haloHaloContract = _haloHaloContract;
    halo = _halo;
  }

  event SentVestedRewardsEvent(uint256 currentVestedRewards);
  event ReleasedRewardsToRewardsContractEvent(uint256 currentReleasedRewards);

  function releaseEpochRewards(uint256 _amount) external onlyOwner {
    uint256 currentHaloBalance = halo.balanceOf(address(this));
    if (currentHaloBalance > 0) {
      // Transfer to halohalo contract
      transferToHaloHaloContract(currentHaloBalance);
    }

    halo.transferFrom(msg.sender, address(this), _amount);

    uint256 currentVestedRewards = _amount.mul(vestingRatio).div(BASIS_POINTS);
    uint256 currentRewardsReleased = _amount.sub(currentVestedRewards);

    // Transfer to rewards contract
    convertAndTransferToRewardsContract(currentRewardsReleased);
  }

  /****************************************
   *            ADMIN FUNCTIONS           *
   ****************************************/
  function setVestingRatio(uint256 _newVestingRatio) external onlyOwner {
    require(_newVestingRatio > 0, 'Vesting ratio cannot be zero!');
    vestingRatio = _newVestingRatio;
  }

  function setRewardsContract(address _rewardsContract) external onlyOwner {
    require(
      _rewardsContract != address(0),
      'Rewards contract cannot be empty!'
    );
    rewardsContract = _rewardsContract;
  }

  function setHaloHaloContract(address _haloHaloContract) external onlyOwner {
    require(
      _haloHaloContract != address(0),
      'Halohalo contract cannot be empty!'
    );
    haloHaloContract = _haloHaloContract;
  }

  /****************************************
   *            VIEW FUNCTIONS            *
   ****************************************/
  function getVestingRatio() external view returns (uint256) {
    return vestingRatio;
  }

  function getRewardsContract() external view returns (address) {
    return rewardsContract;
  }

  function getHaloHaloContract() external view returns (address) {
    return haloHaloContract;
  }

  /****************************************
   *            UTILITY FUNCTIONS          *
   ****************************************/

  function transferToHaloHaloContract(uint256 _amount) internal {
    halo.transfer(haloHaloContract, _amount);
    emit SentVestedRewardsEvent(_amount);
  }

  function convertAndTransferToRewardsContract(uint256 _amount) internal {
    halo.approve(haloHaloContract, _amount);
    HaloHalo(haloHaloContract).enter(_amount);
    uint256 currentHaloHaloBalance = HaloHalo(haloHaloContract).balanceOf(address(this));

    require(currentHaloHaloBalance > 0, 'No HALOHALO in contract');
    AmmRewards(rewardsContract).setRewardTokenPerSecond(currentHaloHaloBalance.div(2592000));
    HaloHalo(haloHaloContract).safeTransfer(rewardsContract, currentHaloHaloBalance);
    emit ReleasedRewardsToRewardsContractEvent(currentHaloHaloBalance);
  }
}
