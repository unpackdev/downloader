// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Pausable.sol";
import "./Ownable.sol";
import "./Math.sol";
import "./EnumerableSet.sol";

/// @title Celestial Vault
contract CelestialVault is Ownable, Pausable {
  using EnumerableSet for EnumerableSet.UintSet;

  /* -------------------------------------------------------------------------- */
  /*                                Farming State                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Rewards end timestamp.
  uint256 public endTime;

  /// @notice Rewards emitted per day staked.
  uint256 public rate;

  /// @notice Staking token contract address.
  ICKEY public stakingToken;

  /// @notice Rewards token contract address.
  IFBX public rewardToken;

  /// @notice Set of staked token ids by address.
  mapping(address => EnumerableSet.UintSet) internal _depositedIds;

  /// @notice Mapping of timestamps from each staked token id.
  // mapping(address => mapping(uint256 => uint256)) internal _depositedBlocks;
    mapping(address => mapping(uint256 => uint256)) public _depositedBlocks;


  constructor(
    address newStakingToken,
    address newRewardToken,
    uint256 newRate,
    uint256 newEndTime
  ) {
    stakingToken = ICKEY(newStakingToken);
    rewardToken = IFBX(newRewardToken);
    rate = newRate;
    endTime = newEndTime;

    _pause();
  }

  /* -------------------------------------------------------------------------- */
  /*                                Farming Logic                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Deposit tokens into the vault.
  /// @param tokenIds Array of token tokenIds to be deposited.
  function deposit(uint256[] memory tokenIds) external whenNotPaused {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      // Add the new deposit to the mapping
      _depositedIds[msg.sender].add(tokenIds[i]);
      _depositedBlocks[msg.sender][tokenIds[i]] = block.timestamp;

      // Transfer the deposited token to this contract
      stakingToken.transferFrom(msg.sender, address(this), tokenIds[i]);
    }
  }

  /// @notice Withdraw tokens and claim their pending rewards.
  /// @param tokenIds Array of staked token ids.
  function withdraw(uint256[] memory tokenIds) external whenNotPaused {
    uint256 totalRewards;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(_depositedIds[msg.sender].contains(tokenIds[i]), "Query for a token you don't own");
      totalRewards += _earned(_depositedBlocks[msg.sender][tokenIds[i]]);
      _depositedIds[msg.sender].remove(tokenIds[i]);
      delete _depositedBlocks[msg.sender][tokenIds[i]];

      stakingToken.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
    }
    rewardToken.mint(msg.sender, totalRewards);
  }

  /// @notice Claim pending token rewards.
  function claim() external whenNotPaused {
    for (uint256 i = 0; i < _depositedIds[msg.sender].length(); i++) {
      // Mint the new tokens and update last checkpoint
      uint256 tokenId = _depositedIds[msg.sender].at(i);
      rewardToken.mint(msg.sender, _earned(_depositedBlocks[msg.sender][tokenId]));
      _depositedBlocks[msg.sender][tokenId] = block.timestamp;
    }
  }

  /// @notice Calculate total rewards for given account.
  /// @param account Holder address.
  function earned(address account) external view returns (uint256[] memory) {
    uint256 length = _depositedIds[account].length();
    uint256[] memory rewards = new uint256[](length);

    for (uint256 i = 0; i < length; i++){
      uint256 tokenId = _depositedIds[account].at(i);
      rewards[i] = _earned(_depositedBlocks[account][tokenId]);
    } 
    return rewards;
  }

  /// @notice Internally calculates rewards for given token.
  /// @param timestamp Deposit timestamp.
  function _earned(uint256 timestamp) internal view returns (uint256) {
    if (timestamp == 0) return 0;
    return ((Math.min(block.timestamp, endTime) - timestamp) * rate) / 1 days;
  }

  /// @notice Retrieve token ids deposited by account.
  /// @param account Token owner address.
  function depositsOf(address account) external view returns (uint256[] memory) {
    uint256 length = _depositedIds[account].length();
    uint256[] memory ids = new uint256[](length);

    for (uint256 i = 0; i < length; i++) ids[i] = _depositedIds[account].at(i);
    return ids;
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
    require(newEndTime > block.timestamp, "CelestialVault: end time must be greater than now");
    endTime = newEndTime;
  }

  /// @notice Set the new staking token contract address.
  /// @param newStakingToken Staking token address.
  function setStakingToken(address newStakingToken) external onlyOwner {
    stakingToken = ICKEY(newStakingToken);
  }

  /// @notice Set the new reward token contract address.
  /// @param newRewardToken Rewards token address.
  function setRewardToken(address newRewardToken) external onlyOwner {
    rewardToken = IFBX(newRewardToken);
  }

  /// @notice Pause the contract.
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice Unpause the contract.
  function unpause() external onlyOwner {
    _unpause();
  }
}

interface ICKEY {
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

interface IFBX {
  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;
}
