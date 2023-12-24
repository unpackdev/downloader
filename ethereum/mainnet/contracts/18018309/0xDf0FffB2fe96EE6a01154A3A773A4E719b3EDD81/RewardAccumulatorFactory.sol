// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Ownable2StepUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./IBeaconUpgradeable.sol";
import "./BeaconProxy.sol";

import "./IRewardAccumulatorFactory.sol";
import "./IRareStakingRegistry.sol";
import "./RewardAccumulator.sol";

/// @author charlescrain
/// @title RewardAccumulatorFactory
/// @notice The RewardAccumulator Factory that creates RewardAccumulator contracts.
contract RewardAccumulatorFactory is
  IRewardAccumulatorFactory,
  IBeaconUpgradeable,
  Ownable2StepUpgradeable,
  UUPSUpgradeable
{
  /*//////////////////////////////////////////////////////////////////////////
                          Private Contract Storage
  //////////////////////////////////////////////////////////////////////////*/

  address private rewardTemplate;

  /*//////////////////////////////////////////////////////////////////////////
                              Constructor
  //////////////////////////////////////////////////////////////////////////*/
  constructor() {
    _disableInitializers();
  }

  /*//////////////////////////////////////////////////////////////////////////
                              Initializer
  //////////////////////////////////////////////////////////////////////////*/

  function initialize(address _rewardTemplate, address _newOwner) external initializer {
    if(_rewardTemplate == address(0)) revert ZeroAddressUnsupported();
    if(_newOwner == address(0)) revert ZeroAddressUnsupported();
    rewardTemplate = _rewardTemplate;
    __Ownable_init();
    __UUPSUpgradeable_init();
    _transferOwnership(_newOwner);
  }

  /*//////////////////////////////////////////////////////////////////////////
                          Internal UUPS Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @inheritdoc UUPSUpgradeable
  function _authorizeUpgrade(address _implementation) internal override onlyOwner {
    if(_implementation == address(0)) revert ZeroAddressUnsupported();
  }

  /*//////////////////////////////////////////////////////////////////////////
                          Admin Write Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @inheritdoc IRewardAccumulatorFactory
  /// @dev Requires the caller to be the owner of the contract.
  function setRewardAccumulatorTemplate(address _rewardTemplate) external onlyOwner {
    if(_rewardTemplate == address(0)) revert ZeroAddressUnsupported();
    rewardTemplate = _rewardTemplate;
    emit RewardAccumulatorTemplateUpdated(_rewardTemplate);
  }

  /*//////////////////////////////////////////////////////////////////////////
                          External Write Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Deploys a RewardAccumulator contract.
  /// @param _stakingAddress Address of staking contract.
  /// @return address Address of the RewardAccumulator contract.
  function deployRewardSwap(address _stakingAddress) public returns (address payable) {
    if(_stakingAddress == address(0)) revert ZeroAddressUnsupported();
    BeaconProxy newRewardSwap = new BeaconProxy(
      address(this),
      abi.encodeWithSelector(RewardAccumulator.initialize.selector, address(_stakingAddress))
    );

    emit RewardSwapContractCreated(address(newRewardSwap));
    return payable(address(newRewardSwap));
  }

  /*//////////////////////////////////////////////////////////////////////////
                          External Read Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @inheritdoc IRewardAccumulatorFactory
  function getRewardSwapTemplateAddress() external view returns (address) {
    return rewardTemplate;
  }

  /// @inheritdoc IBeaconUpgradeable
  function implementation() external view returns (address) {
    return rewardTemplate;
  }
}
