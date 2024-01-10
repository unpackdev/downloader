// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Pausable.sol";
import "./Ownable.sol";
import "./Math.sol";
import "./EnumerableSet.sol";

/// @title Ape Runners Staking
/// @author naomsa <https://twitter.com/naomsa666>
contract ApeRunnersStaking is Ownable, Pausable {
  using EnumerableSet for EnumerableSet.UintSet;

  /* -------------------------------------------------------------------------- */
  /*                                Farming State                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Rewards end timestamp.
  uint256 public endTime;

  /// @notice Rewards emitted per day staked.
  uint256 public rate;

  /// @notice Staking token contract address.
  IStakingToken public stakingToken;

  /// @notice Rewards token contract address.
  IRewardToken public rewardToken;

  /// @notice Set of staked token ids by address.
  mapping(address => EnumerableSet.UintSet) internal _depositsOf;

  /// @notice Mapping of timestamps from each staked token id.
  mapping(uint256 => uint256) internal _depositedAt;

  constructor(
    address newStakingToken,
    address newRewardToken,
    uint256 newRate,
    uint256 newEndTime
  ) {
    stakingToken = IStakingToken(newStakingToken);
    rewardToken = IRewardToken(newRewardToken);
    rate = newRate;
    endTime = newEndTime;
  }

  /* -------------------------------------------------------------------------- */
  /*                                Farming Logic                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Deposit tokens into the vault.
  /// @param tokenIds Array of token tokenIds to be deposited.
  function deposit(uint256[] calldata tokenIds) external whenNotPaused {
    for (uint256 i; i < tokenIds.length; i++) {
      // Add the new deposit to the mapping
      _depositsOf[msg.sender].add(tokenIds[i]);
      _depositedAt[tokenIds[i]] = block.timestamp;

      // Transfer the deposited token to this contract
      stakingToken.transferFrom(msg.sender, address(this), tokenIds[i]);
    }
  }

  /// @notice Withdraw tokens and claim their pending rewards.
  /// @param tokenIds Array of staked token ids.
  function withdraw(uint256[] calldata tokenIds) external whenNotPaused {
    uint256 totalRewards;
    for (uint256 i; i < tokenIds.length; i++) {
      require(
        _depositsOf[msg.sender].contains(tokenIds[i]),
        "Query for a token you don't own"
      );

      totalRewards += _earned(_depositedAt[tokenIds[i]]);
      _depositsOf[msg.sender].remove(tokenIds[i]);
      delete _depositedAt[tokenIds[i]];

      stakingToken.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
    }

    rewardToken.mint(msg.sender, totalRewards);
  }

  /// @notice Claim pending token rewards.
  function claim() external whenNotPaused {
    for (uint256 i; i < _depositsOf[msg.sender].length(); i++) {
      // Mint the new tokens and update last checkpoint
      uint256 tokenId = _depositsOf[msg.sender].at(i);
      rewardToken.mint(msg.sender, _earned(_depositedAt[tokenId]));

      _depositedAt[tokenId] = block.timestamp;
    }
  }

  /// @notice Calculate total rewards for given account.
  /// @param account Holder address.
  function earned(address account)
    external
    view
    returns (uint256[] memory rewards)
  {
    uint256 length = _depositsOf[account].length();
    rewards = new uint256[](length);

    for (uint256 i; i < length; i++) {
      rewards[i] = _earned(_depositedAt[_depositsOf[account].at(i)]);
    }
  }

  /// @notice Internally calculates rewards for given token.
  /// @param timestamp Deposit timestamp.
  function _earned(uint256 timestamp) internal view returns (uint256) {
    if (timestamp == 0) return 0;
    return ((Math.min(block.timestamp, endTime) - timestamp) * rate) / 1 days;
  }

  /// @notice Retrieve token ids deposited by account.
  /// @param account Token owner address.
  function depositsOf(address account)
    external
    view
    returns (uint256[] memory ids)
  {
    uint256 length = _depositsOf[account].length();
    ids = new uint256[](length);
    for (uint256 i; i < length; i++) ids[i] = _depositsOf[account].at(i);
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Owner Logic                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Set the new token rewards rate.
  /// @param newRate Emission rate in wei.
  function setRate(uint256 newRate) external onlyOwner {
    rate = newRate;
  }

  /// @notice Set the new rewards end time.
  /// @param newEndTime End timestamp.
  function setEndTime(uint256 newEndTime) external onlyOwner {
    require(newEndTime > block.timestamp, "End time must be greater than now");
    endTime = newEndTime;
  }

  /// @notice Set the new staking token contract address.
  /// @param newStakingToken Staking token address.
  function setStakingToken(address newStakingToken) external onlyOwner {
    stakingToken = IStakingToken(newStakingToken);
  }

  /// @notice Set the new reward token contract address.
  /// @param newRewardToken Rewards token address.
  function setRewardToken(address newRewardToken) external onlyOwner {
    rewardToken = IRewardToken(newRewardToken);
  }

  /// @notice Toggle if the contract is paused.
  function togglePaused() external onlyOwner {
    if (paused()) _unpause();
    else _pause();
  }
}

interface IStakingToken {
  function transferFrom(
    address from,
    address to,
    uint256 id
  ) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 id
  ) external;
}

interface IRewardToken {
  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;
}
