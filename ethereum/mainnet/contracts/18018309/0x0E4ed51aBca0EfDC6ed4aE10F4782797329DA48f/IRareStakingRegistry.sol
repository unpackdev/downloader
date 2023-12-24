// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author koloz, charlescrain
/// @title IRareStakingRegistry
/// @notice The Staking Registry interface containing all functions, events, etc.
interface IRareStakingRegistry {
  /*//////////////////////////////////////////////////////////////////////////
                              Structs
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice A struct holding the information about the target's staking contract.
  /// @dev Target being staked on is omitted as it's the key in the mapping used.
  struct Info {
    string name;
    string symbol;
    address stakingAddress;
    address rewardAddress;
  }

  /*//////////////////////////////////////////////////////////////////////////
                              Events
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Emitted via {setDefaultPayee} when the defaultPayee is updated.
  event DefaultPayeeUpdated(address _payee);

  /// @notice Emitted via {setDeflationaryPercentage} when the deflationaryPercentage is updated.
  event DeflationaryPercentageUpdated(uint256 _percentage);

  /// @notice Emitted via {setDiscountPercentage} when the discountedPercent is updated.
  event DiscountPercentageUpdated(uint256 _percentage);

  /// @notice Emitted via {setPeriodLength} when the periodLength is updated.
  event PeriodLengthUpdated(uint256 _periodLength);

  /// @notice Emitted via {setReverseRegistrar} when the ENS reverse registrar is updated.
  event ReverseRegistrarUpdated(address _percentage);

  /// @notice Emitted via {setResolver} when the ENS resolver is updated.
  event ResolverUpdated(address _resolver);

  /// @notice Emitted via {setSwapPool} when a new swap pool has been set.
  event SetSwapPool(address _uniswapPool, address _token);

  /*//////////////////////////////////////////////////////////////////////////
                            Custom Errors
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Emitted when guarded functions are called by users without the necessary permissions.
  error Unauthorized();

  /// @notice Emitted via {setSwapPool} if the pool doesn't match the token and pairs with WETH.
  error InvalidPool();

  /// @notice Emitted via {setStakingAddress} if the user already has a staking address.
  error StakingContractAlreadyExists();

  /// @notice Emitted when Zero address provided where it is not allowed.
  error ZeroAddressUnsupported();

  /// @notice Error emitted in {transferRareFrom} when a user performs an action that requires moving $RARE but has not made enough allowance for the registry.
  error InsufficientRareAllowance();

  /// @notice Emitted when a percentage is beyond the specified limit.
  error PercentageBeyondLimit();

  /// @notice Emitted when a Period Length is beyond the specified limit.
  error PeriodLengthBeyondLimit();

  /// @notice Emitted when renouncing the admin role and no other account has the role.
  error RenouncingAdmin();

  /*//////////////////////////////////////////////////////////////////////////
                          External Write Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Increase amount staked when a user stakes.
  /// @param _staker The user who is staking.
  /// @param _stakedOn The user who is being staked on.
  /// @param _amount The amount of $RARE that has been staked.
  function increaseAmountStaked(
    address _staker,
    address _stakedOn,
    uint256 _amount
  ) external;

  /// @notice Decrease the amount staked when a user unstakes.
  /// @param _staker The user who is unstaking.
  /// @param _stakedOn The user who was being staked on.
  /// @param _amount The amount of $RARE that has been unstaked.
  function decreaseAmountStaked(
    address _staker,
    address _stakedOn,
    uint256 _amount
  ) external;

  /// @notice Set staking addresses for a target.
  /// @param _user Address of the target whose staking address is being set.
  /// @param _stakingAddress Address of the staking pool contract.
  /// @param _rewardSwapAddress Address of the reward swap contract.
  function setStakingAddresses(
    address _user,
    address _stakingAddress,
    address _rewardSwapAddress
  ) external;

  /// @notice Set the default payee.
  /// @param _payee Address of the account to be the new default payee.
  function setDefaultPayee(address _payee) external;

  /// @notice Set the reward swap discount percentage.
  /// @param _percentage The new discount percentage.
  function setDiscountPercentage(uint256 _percentage) external;

  /// @notice Set the unstake deflationary percentage.
  /// @param _percentage The new deflactionary percentage.
  function setDeflationaryPercentage(uint256 _percentage) external;

  /// @notice Set the round period length time.
  /// @param _periodLength The new period start.
  function setPeriodLength(uint256 _periodLength) external;

  /// @notice Set the ENS reverse registrar address.
  /// @param _reverseRegistrar The new period start.
  function setReverseRegistrar(address _reverseRegistrar) external;

  /// @notice Set the ENS resolver address.
  /// @param _resolver The new period start.
  function setResolver(address _resolver) external;

  /// @notice Set the uniswap pool address for the given ERC20 token.
  /// @param _uniswapPool Address of  uniswap pool.
  /// @param _token Address of  ERC20 contract.
  function setSwapPool(address _uniswapPool, address _token) external;

  /// @notice Pools to transfer $RARE tokens, usually into pools. This is so users only need to approve the registry when staking or performing reward swaps.
  /// @param _from Address to transfer the tokens from.
  /// @param _to Address to transfer the tokens to.
  /// @param _amount uint256 amount to transfer.
  function transferRareFrom(
    address _from,
    address _to,
    uint256 _amount
  ) external;

  /*//////////////////////////////////////////////////////////////////////////
                          External Read Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Get the address for sending rewards if there are no stakers.
  /// @return address to send rewards to.
  function getDefaultPayee() external view returns (address);

  /// @notice Get the swap pool address for the ERC20 token.
  /// @return address of the swap pool associated with the token.
  function getSwapPool(address _token) external view returns (address);

  /// @notice Retrieve the address of $RARE.
  /// @return address Address of $RARE (the staking token to be used).
  function getRareAddress() external view returns (address);

  /// @notice Retrieve the address of Wrapped Ethereum.
  /// @return address Address of Wrapped Ethereum.
  function getWethAddress() external view returns (address);

  /// @notice Get reward swap discount percentage.
  /// @return uint256  discount percentage.
  function getDiscountPercentage() external view returns (uint256);

  /// @notice Get the unstake deflationary percentage.
  /// @return uint256 deflationary percentage.
  function getDeflationaryPercentage() external view returns (uint256);

  /// @notice Get the round period length.
  /// @return uint256 period length.
  function getPeriodLength() external view returns (uint256);

  /// @notice Retrieves the staking info for a given user.
  /// @param _user Address of user being queried.
  /// @return Info struct containing name, symbol, staking address, and reward accumulator address.
  function getStakingInfoForUser(address _user) external view returns (Info memory);

  /// @notice Retrieves the staking address for a given user.
  /// @param _user Address of user being queried.
  /// @return address staking address.
  function getStakingAddressForUser(address _user) external view returns (address);

  /// @notice Retrieves the reward accumulator address for a given user.
  /// @param _user Address of user being queried.
  /// @return address Reward accumulator address.
  function getRewardAccumulatorAddressForUser(address _user) external view returns (address);

  /// @notice Retrieves the total amount of rare staked by a given user.
  /// @param _user Address of the user staking.
  /// @return uint256 Amount of rare the user is staking.
  function getTotalAmountStakedByUser(address _user) external view returns (uint256);

  /// @notice Retrieves the total amount of rare being staked on a given user.
  /// @param _user Address of the user being staked on.
  /// @return uint256 Amount of rare being staked on the user.
  function getTotalAmountStakedOnUser(address _user) external view returns (uint256);

  /// @notice Query the users for the following staking addresseses.
  /// @param _stakingAddrs Addresses of staking contracts being queried.
  function getUsersForStakingAddresses(address[] calldata _stakingAddrs) external view returns (address[] memory);

  /// @notice Bytes32 representation of the role used for setting the staking address of a user.
  /// @return bytes32 value of the staking info setter role.
  function STAKING_INFO_SETTER_ROLE() external view returns (bytes32);

  /// @notice Bytes32 representation of the admin role for granting the ability to set amount staked for a single user/total amount staked on a user.
  /// @return bytes32 value of the staking stat setter admin role.
  function STAKING_STAT_SETTER_ADMIN_ROLE() external view returns (bytes32);

  /// @notice Bytes32 representation of the role used for updating the amount being staked on a user/amount a user is staking globally.
  /// @return bytes32 value of the stat setter role.
  function STAKING_STAT_SETTER_ROLE() external view returns (bytes32);

  /// @notice Bytes32 representation of the role used for period length, deflationary percentages, and the default payee.
  /// @return bytes32 value of the staking config setter role.
  function STAKING_CONFIG_SETTER_ROLE() external view returns (bytes32);

  /// @notice Bytes32 representation of the role used for updating the ENS resolvers.
  /// @return bytes32 value of the ens setter role.
  function ENS_SETTER_ROLE() external view returns (bytes32);

  /// @notice Bytes32 representation of the role used for updating uniswap pools.
  /// @return bytes32 value of the swap pool setter role.
  function SWAP_POOL_SETTER_ROLE() external view returns (bytes32);
}
