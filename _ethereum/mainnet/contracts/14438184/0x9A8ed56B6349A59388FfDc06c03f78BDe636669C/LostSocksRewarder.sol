// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./MathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./Initializable.sol";

import "./ILostSocksGenesis.sol";
import "./ILostSocksThread.sol";

/// @title Lost Socks Rewarder
contract LostSocksRewarder is Initializable, OwnableUpgradeable, PausableUpgradeable {
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

  /* -------------------------------------------------------------------------- */
  /*                                Farming State                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Rewards end timestamp.
  uint256 public endTime;

  /// @notice Rewards emitted per day staked.
  uint256 public rate;

  /// @notice Staking token contract address.
  ILostSocksGenesis public stakingToken;

  /// @notice Rewards token contract address.
  ILostSocksThread public rewardToken;

  /// @notice Set of staked token ids by address.
  mapping(address => EnumerableSetUpgradeable.UintSet) internal _depositedIds;

  /// @notice Mapping of timestamps from each staked token id.
  mapping(uint256 => uint256) internal _depositedTimestamps;

  function initialize(
    address newStakingToken,
    address newRewardToken,
    uint256 newRate,
    uint256 newEndTime
  ) external initializer {
    __Ownable_init();
    __Pausable_init();

    stakingToken = ILostSocksGenesis(newStakingToken); // Lost Socks Genesis
    rewardToken = ILostSocksThread(newRewardToken); // Lost Socks Thread
    rate = newRate; // Daily emissions by token
    endTime = newEndTime; // End date timemstamp

    _pause();
  }

  /* -------------------------------------------------------------------------- */
  /*                                Farming Logic                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Deposit tokens into the vault.
  /// @param tokenIds Array of token tokenIds to be deposited.
  function deposit(uint256[] calldata tokenIds) external whenNotPaused {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      // Add the new deposit to the mapping
      _depositedIds[msg.sender].add(tokenIds[i]);
      _depositedTimestamps[tokenIds[i]] = block.timestamp;

      // Transfer the deposited token to this contract
      stakingToken.transferFrom(msg.sender, address(this), tokenIds[i]);
    }
  }

  /// @notice Withdraw tokens and claim their pending rewards.
  /// @param tokenIds Array of staked token ids.
  function withdraw(uint256[] calldata tokenIds) external whenNotPaused {
    uint256 totalRewards;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(_depositedIds[msg.sender].contains(tokenIds[i]), "Query for a token you don't own");

      totalRewards += _earned(_depositedTimestamps[tokenIds[i]], stakingToken.isLeft(tokenIds[i]));
      _depositedIds[msg.sender].remove(tokenIds[i]);
      delete _depositedTimestamps[tokenIds[i]];

      stakingToken.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
    }

    rewardToken.mint(msg.sender, totalRewards);
  }

  /// @notice Claim pending token rewards.
  function claim() external whenNotPaused {
    for (uint256 i = 0; i < _depositedIds[msg.sender].length(); i++) {
      // Mint the new tokens and update last checkpoint
      uint256 tokenId = _depositedIds[msg.sender].at(i);
      rewardToken.mint(msg.sender, _earned(_depositedTimestamps[tokenId], stakingToken.isLeft(tokenId)));

      _depositedTimestamps[tokenId] = block.timestamp;
    }
  }

  /// @notice Calculate total rewards for given account.
  /// @param account Holder address.
  function earned(address account) external view returns (uint256[] memory rewards) {
    uint256 length = _depositedIds[account].length();
    rewards = new uint256[](length);

    for (uint256 i = 0; i < length; i++) {
      uint256 tokenId = _depositedIds[account].at(i);
      rewards[i] = _earned(_depositedTimestamps[tokenId], stakingToken.isLeft(tokenId));
    }
  }

  /// @notice Internally calculates rewards for given token.
  /// @param timestamp Deposit timestamp.
  /// @param isLeft Whether the sock is left or right, giving it double yield in the first case.
  function _earned(uint256 timestamp, bool isLeft) internal view returns (uint256) {
    if (timestamp == 0) return 0;
    uint256 rewards = ((MathUpgradeable.min(block.timestamp, endTime) - timestamp) * rate) / 1 days;
    return isLeft ? rewards * 2 : rewards;
  }

  /// @notice Retrieve token ids deposited by account.
  /// @param account Token owner address.
  function depositsOf(address account) external view returns (uint256[] memory ids) {
    uint256 length = _depositedIds[account].length();
    ids = new uint256[](length);
    for (uint256 i; i < length; i++) ids[i] = _depositedIds[account].at(i);
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
    stakingToken = ILostSocksGenesis(newStakingToken);
  }

  /// @notice Set the new reward token contract address.
  /// @param newRewardToken Rewards token address.
  function setRewardToken(address newRewardToken) external onlyOwner {
    rewardToken = ILostSocksThread(newRewardToken);
  }

  /// @notice Toggle if the contract is paused.
  function togglePaused() external onlyOwner {
    if (paused()) _unpause();
    else _pause();
  }
}
