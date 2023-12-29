// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Ownable2StepUpgradeable.sol";
import "./IAccessControlUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./IBeaconUpgradeable.sol";

import "./BeaconProxy.sol";

import "./IRarityPoolFactory.sol";
import "./IRewardAccumulatorFactory.sol";
import "./IRareStakingRegistry.sol";
import "./IRarityPool.sol";

/// @author koloz, charlescrain
/// @title RarityPoolFactory
/// @notice The Staking Factory Contract used to deploy new staking ERC20 contracts pertaining to a user.
/// @dev Made to be used with a UUPS Proxy.
contract RarityPoolFactory is IRarityPoolFactory, IBeaconUpgradeable, Ownable2StepUpgradeable, UUPSUpgradeable {
  /*//////////////////////////////////////////////////////////////////////////
                          Private Contract Storage
  //////////////////////////////////////////////////////////////////////////*/

  // Staking registry contract
  IRareStakingRegistry private stakingRegistry;

  // Reward swap factory contract
  IRewardAccumulatorFactory private rewardSwapFactory;

  // Template contract used for Beacon implementation
  address private rareStakingTemplate;

  /*//////////////////////////////////////////////////////////////////////////
                              Constructor
  //////////////////////////////////////////////////////////////////////////*/
  constructor() {
    _disableInitializers();
  }

  /*//////////////////////////////////////////////////////////////////////////
                              Initializer
  //////////////////////////////////////////////////////////////////////////*/

  function initialize(
    address _stakingRegistry,
    address _rareStakingTemplate,
    address _rewardSwapFactory,
    address _newOwner
  ) external initializer {
    if (_stakingRegistry == address(0)) revert ZeroAddressUnsupported();
    if (_rareStakingTemplate == address(0)) revert ZeroAddressUnsupported();
    if (_rewardSwapFactory == address(0)) revert ZeroAddressUnsupported();
    if (_newOwner == address(0)) revert ZeroAddressUnsupported();
    rewardSwapFactory = IRewardAccumulatorFactory(_rewardSwapFactory);
    rareStakingTemplate = _rareStakingTemplate;
    stakingRegistry = IRareStakingRegistry(_stakingRegistry);
    __Ownable_init();
    __UUPSUpgradeable_init();
    _transferOwnership(_newOwner);
  }

  /*//////////////////////////////////////////////////////////////////////////
                          Internal UUPS Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @inheritdoc UUPSUpgradeable
  function _authorizeUpgrade(address _implementation) internal override onlyOwner {
    if (_implementation == address(0)) revert ZeroAddressUnsupported();
  }

  /*//////////////////////////////////////////////////////////////////////////
                          Admin Write Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @inheritdoc IRarityPoolFactory
  /// @dev Requires the caller to be the owner of the contract.
  function setStakingRegistry(address _stakingRegistry) external onlyOwner {
    if (_stakingRegistry == address(0)) revert ZeroAddressUnsupported();
    stakingRegistry = IRareStakingRegistry(_stakingRegistry);
    emit StakingRegistryUpdated(_stakingRegistry);
  }

  /// @inheritdoc IRarityPoolFactory
  /// @dev Requires the caller to be the owner of the contract.
  function setRareStakingTemplate(address _rareStakingTemplate) external onlyOwner {
    if (_rareStakingTemplate == address(0)) revert ZeroAddressUnsupported();
    rareStakingTemplate = _rareStakingTemplate;
    emit RareStakingTemplateUpdated(_rareStakingTemplate);
  }

  /*//////////////////////////////////////////////////////////////////////////
                          External Write Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @inheritdoc IRarityPoolFactory
  /// @dev This contract must have the {STAKING_INFO_SETTER_ROLE} role on {RareStakingRegistry}.
  function deployStaking(address _user) public returns (address) {
    IRareStakingRegistry registry = stakingRegistry;
    if (_user == address(0)) revert ZeroAddressUnsupported();
    BeaconProxy newStaking = new BeaconProxy(
      address(this),
      abi.encodeWithSelector(IRarityPool.initialize.selector, _user, address(registry), msg.sender)
    );
    address rewardSwap = rewardSwapFactory.deployRewardSwap(address(newStaking));
    registry.setStakingAddresses(_user, address(newStaking), rewardSwap);

    bytes32 statSetterRole = registry.STAKING_STAT_SETTER_ROLE();

    IAccessControlUpgradeable(address(registry)).grantRole(statSetterRole, address(newStaking));

    emit IRarityPoolFactory.StakingContractCreated(msg.sender, _user, address(newStaking));

    return address(newStaking);
  }

  /*//////////////////////////////////////////////////////////////////////////
                          External Read Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @inheritdoc IRarityPoolFactory
  function getStakingRegistryAddress() external view returns (address) {
    return address(stakingRegistry);
  }

  /// @inheritdoc IRarityPoolFactory
  function getRareStakingTemplateAddress() external view returns (address) {
    return rareStakingTemplate;
  }

  /// @inheritdoc IBeaconUpgradeable
  function implementation() external view returns (address) {
    return rareStakingTemplate;
  }
}
