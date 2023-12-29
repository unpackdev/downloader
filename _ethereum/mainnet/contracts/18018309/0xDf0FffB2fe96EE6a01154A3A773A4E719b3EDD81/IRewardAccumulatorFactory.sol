// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author charlescrain
/// @title IRewardAccumulatorFactory
/// @notice The RewardAccumulator Factory interface containing all functions, events, etc.
interface IRewardAccumulatorFactory {
  /*//////////////////////////////////////////////////////////////////////////
                              Events
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Emitted via {deployRewardSwap} when a new RewardAccumulator contract is deployed.
  event RewardSwapContractCreated(address indexed _stakingAddress);

  /// @notice Emitted via {setRewardAccumulatorTemplate} when the RewardAccumulatorTemplate is upaded.
  event RewardAccumulatorTemplateUpdated(address indexed rewardTemplate);

  /*//////////////////////////////////////////////////////////////////////////
                            Custom Errors
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Emitted when Zero address provided where it is not allowed.
  error ZeroAddressUnsupported();

  /*//////////////////////////////////////////////////////////////////////////
                          External Write Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Deploys a RewardAccumulator contract.
  /// @param _stakingAddress Address of staking contract.
  /// @return address Address of the RewardAccumulator contract.
  function deployRewardSwap(address _stakingAddress) external returns (address payable);

  /// @notice Set the RewardAccumulator template address to be used.
  /// @param _rewardTemplate Address of the RewardAccumulator template.
  function setRewardAccumulatorTemplate(address _rewardTemplate) external;

  /*//////////////////////////////////////////////////////////////////////////
                          External Read Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Retrieve the template contract
  /// @return address Address of the template.
  function getRewardSwapTemplateAddress() external view returns (address);
}
