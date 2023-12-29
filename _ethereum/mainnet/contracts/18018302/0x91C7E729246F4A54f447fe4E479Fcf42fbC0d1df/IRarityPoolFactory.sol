// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author koloz, charlescrain
/// @title IRarityPoolFactory
/// @notice The Staking Factory interface containing all functions, events, etc.
interface IRarityPoolFactory {
  /*//////////////////////////////////////////////////////////////////////////
                              Events
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Emitted via {deployStaking} when a new staking contract is deployed.
  event StakingContractCreated(
    address indexed _deployingUser,
    address indexed _userStakedOn,
    address indexed _stakingAddress
  );

  /// @notice Emitted via {setRareStakingTemplate} when the staking template is updated.
  event RareStakingTemplateUpdated(address indexed newRareStakingTemplate);
  
  /// @notice Emitted via {setStakingRegistry} when the staking registry is updated.
  event StakingRegistryUpdated(address indexed newStakingRegistry);

  /*//////////////////////////////////////////////////////////////////////////
                            Custom Errors
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Emitted when Zero address provided where it is not allowed.
  error ZeroAddressUnsupported();

  /*//////////////////////////////////////////////////////////////////////////
                          External Write Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Deploys a staking contract for the supplied target address. Reverts if address exists.
  /// @param _user Address of the target to deploy staking contract for.
  /// @return address Address of the staking contract.
  function deployStaking(address _user) external returns (address);

  /// @notice Set the staking registry address field to be used.
  /// @param _stakingRegistry Address of the new staking registry contract.
  function setStakingRegistry(address _stakingRegistry) external;

  /// @notice Set the rare staking ERC20 template address to be used.
  /// @param _rareStakingTemplate Address of the staking ERC20 template.
  function setRareStakingTemplate(address _rareStakingTemplate) external;

  /*//////////////////////////////////////////////////////////////////////////
                          External Read Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Retrieve the currently used staking registry address.
  /// @return address Address of the staking registry contract.
  function getStakingRegistryAddress() external view returns (address);

  /// @notice Retrieve the currently template of the staking ERC20 contract.
  /// @return address Address of the staking ERC20 template to be used.
  function getRareStakingTemplateAddress() external view returns (address);
}
