// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IRewards {
  function updateAmmRewardPool(address _lpAddress) external;

  function updateMinterRewardPool(address _collateralAddress) external;

  // Deposit LP tokens to earn HALO Rewards.
  function deposit(address _lpAddress, uint256 _amount) external;

  function depositMinter(
    address _collateralAddress,
    address _account,
    uint256 _amount
  ) external;

  // Withdraw LP tokens.
  function withdraw(address _lpAddress, uint256 _amount) external;

  function withdrawMinter(
    address _collateralAddress,
    address _account,
    uint256 _amount
  ) external;

  function depositEpochRewardAmount(uint256 _epochRewardAmount) external;

  //===========================================//
  //===============view functions==============//
  //===========================================//

  function getTotalPoolAllocationPoints() external view returns (uint256);

  function getTotalMinterLpAllocationPoints() external view returns (uint256);

  function getPendingPoolRewardsByUserByPool(
    address _lpAddress,
    address _account
  ) external view returns (uint256);

  function getUnclaimedMinterLpRewardsByUser(
    address _collateralAddress,
    address _account
  ) external view returns (uint256);

  //utility view functions
  function isValidAmmLp(address _lpAddress) external view returns (bool);

  function isValidMinterLp(address _collateralAddress)
    external
    view
    returns (bool);

  function setAmmLpAllocationPoints(address _lpAddress, uint256 _allocPoint)
    external;

  function setMinterLpAllocationPoints(
    address _collateralAddress,
    uint256 _allocPoint
  ) external;

  function addAmmLp(address _lpAddress, uint256 _allocPoint) external;

  function addMinterCollateralType(
    address _collateralAddress,
    uint256 _allocPoint
  ) external;

  function removeLp(address _lpAddress) external;

  function removeMinterCollateralType(address _collateralAddress) external;

  function setMinter(address _minter) external;
}
