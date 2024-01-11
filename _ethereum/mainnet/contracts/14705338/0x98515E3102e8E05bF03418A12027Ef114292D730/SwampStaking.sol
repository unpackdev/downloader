// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC721Enumerable.sol";
import "./ERC721Holder.sol";
import "./Ownable.sol";
import "./ICroak.sol";

/// @title Swampverse: Staking (v2)
/// @author @ryeshrimp

contract SwampStaking is Initializable, ERC721Holder, ReentrancyGuardUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    
  uint32 public constant SECONDS_IN_DAY = 1 days;

  ICroak public rewardsToken;
  IERC721Enumerable public swamperToken;
  IERC721Enumerable public creatureToken;

  struct UserInfo {
    uint256 stakedCreatureCount;
    uint256 stakedSwamperCount;
    uint256 pendingRewards;
    uint256 lastUpdate;
  }

  mapping(address => bool) controllers;

  mapping(address => UserInfo) public userInfo;
  mapping(uint256 => address) public stakedCreatures;
  mapping(uint256 => address) public stakedSwampers;

  uint256 public swamperRewardPerDay;
  uint256 public creatureRewardPerDay;

  function initialize(
    address _swamperToken,
    address _creatureToken,
    address _rewardsToken,
    uint256 _swamperRewardPerDay,
    uint256 _creatureRewardPerDay
  ) public initializer {

    __Ownable_init();
    __Pausable_init();

    swamperToken = IERC721Enumerable(_swamperToken);
    creatureToken = IERC721Enumerable(_creatureToken);
    rewardsToken = ICroak(_rewardsToken);

    swamperRewardPerDay = _swamperRewardPerDay;
    creatureRewardPerDay = _creatureRewardPerDay;

    controllers[msg.sender] = true;
  }

  /// @notice Total amount of staked assets
  function balanceOf(address owner) public view virtual returns (uint256) {
    return userInfo[owner].stakedSwamperCount + userInfo[owner].stakedCreatureCount;
  }

  /// @notice Calculates live pending rewards of owner
  /// @param account the address of owner
  function pending(address account) public view returns (uint256) {
    return userInfo[account].pendingRewards + (((block.timestamp - userInfo[account].lastUpdate) / SECONDS_IN_DAY) * (userInfo[account].stakedCreatureCount*creatureRewardPerDay)) + (((block.timestamp - userInfo[account].lastUpdate) / SECONDS_IN_DAY) * (userInfo[account].stakedSwamperCount*swamperRewardPerDay));
  }

  /// @notice Returns IDs of staked swampers by owner
  /// @param account the address of owner
  function stakedSwampersByOwner(address account) public view returns (uint256[] memory) {
    uint256 supply = swamperToken.totalSupply();
    uint256[] memory tmp = new uint256[](supply);

    uint256 index;
    for(uint tokenId = 1; tokenId <= supply; tokenId++) {
      if (stakedSwampers[tokenId] == account) {
        tmp[index] = tokenId;
        index++;
      }
    }

    uint256[] memory tokens = new uint256[](index);
    for(uint i; i < index; i++) {
      tokens[i] = tmp[i];
    }

    return tokens;
  }

  /// @notice Returns IDs of staked creatures by owner
  /// @param account the address of owner
  function stakedCreaturesByOwner(address account) public view returns (uint256[] memory) {
    uint256 supply = creatureToken.totalSupply();
    uint256[] memory tmp = new uint256[](supply);

    uint256 index;
    for(uint tokenId = 1; tokenId <= supply; tokenId++) {
      if (stakedCreatures[tokenId] == account) {
        tmp[index] = tokenId;
        index++;
      }
    }

    uint256[] memory tokens = new uint256[](index);
    for(uint i; i < index; i++) {
      tokens[i] = tmp[i];
    }

    return tokens;
  }

  /// @notice Set swamper, creature, or rewards address
  /// @param _mode A number corresponding to the token type
  /// 1 - swamperToken
  /// 2 - creatureToken
  /// 3 - rewardsToken
  function setAddresses(uint8 _mode, address _address) external onlyOwner {
    if (_mode == 1) swamperToken = IERC721Enumerable(_address);
    else if (_mode == 2) creatureToken = IERC721Enumerable(_address);
    else if (_mode == 3) rewardsToken = ICroak(_address);
    else revert("SwampStaking.setAddresses: WRONG_MODE");
  }

  /// @notice Set rewards amount for NFTs
  /// @param _mode A number corresponding to the token type
  /// 1 - swamperRewardPerDay
  /// 2 - creatureRewardPerDay
  function setRewards(uint8 _mode, uint256 _amount) external onlyOwner {
    if (_mode == 1) swamperRewardPerDay = _amount;
    else if (_mode == 2) creatureRewardPerDay = _amount;
    else revert("SwampStaking.setAwards: WRONG_MODE");
  }

  /// @notice Stakes user's Swamper NFTs
  /// @param tokenIds The tokenIds of the Swamper NFTs which will be staked
  function stakeSwampers(uint256[] memory tokenIds) external nonReentrant whenNotPaused updateReward(msg.sender) {
    require(tokenIds.length > 0, "SwampStaking: No tokenIds provided");

    uint256 amount;
    for (uint256 i; i < tokenIds.length;) {
      // Transfer user's NFTs to the staking contract
      swamperToken.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
      // Increment the amount which will be staked
      unchecked { amount++; }
      // Save who is the staker/depositor of the token
      stakedSwampers[tokenIds[i]] = msg.sender;
      unchecked { i++; }
    }

    unchecked { userInfo[msg.sender].stakedSwamperCount += amount; }
    emit Staked(msg.sender, amount, tokenIds, 0);
  }

  /// @notice Stakes user's Creature NFTs
  /// @param tokenIds The tokenIds of the Creature NFTs which will be staked
  function stakeCreatures(uint256[] memory tokenIds) external nonReentrant whenNotPaused updateReward(msg.sender) {
    require(tokenIds.length > 0, "SwampStaking: No tokenIds provided");

    uint256 amount;
    for (uint256 i; i < tokenIds.length;) {
      // Transfer user's NFTs to the staking contract
      creatureToken.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
      // Increment the amount which will be staked
      unchecked { amount++; }
      // Save who is the staker/depositor of the token
      stakedCreatures[tokenIds[i]] = msg.sender;
      unchecked { i++; }
    }

    unchecked { userInfo[msg.sender].stakedCreatureCount += amount; }
    emit Staked(msg.sender, amount, tokenIds, 1);
  }

  /// @notice Withdraws staked swamper NFTs
  /// @param tokenIds The tokenIds of the NFTs which will be withdrawn
  function withdrawSwampers(uint256[] memory tokenIds) external nonReentrant updateReward(msg.sender) {
    require(tokenIds.length > 0, "SwampStaking: No tokenIds provided");

    uint256 amount;
    for (uint256 i; i < tokenIds.length;) {
      // Check if the user who withdraws is the owner
      require(stakedSwampers[tokenIds[i]] == msg.sender, "SwampStaking: Not the staker of the token");
      // Transfer NFTs back to the owner
      swamperToken.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
      // Increment the amount which will be withdrawn
      amount++;
      // Cleanup stakedAssets and paused info for the current tokenId
      stakedSwampers[tokenIds[i]] = address(0);
      unchecked { i++; }
    }

    userInfo[msg.sender].stakedSwamperCount -= amount;
    emit Withdrawn(msg.sender, amount, tokenIds, 0);
  }

  /// @notice Withdraws staked creature NFTs
  /// @param tokenIds The tokenIds of the NFTs which will be withdrawn
  function withdrawCreatures(uint256[] memory tokenIds) external nonReentrant updateReward(msg.sender) {
    require(tokenIds.length > 0, "SwampStaking: No tokenIds provided");

    uint256 amount;
    for (uint256 i; i < tokenIds.length;) {
      // Check if the user who withdraws is the owner
      require(stakedCreatures[tokenIds[i]] == msg.sender, "SwampStaking: Not the staker of the token");
      // Transfer NFTs back to the owner
      creatureToken.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
      // Increment the amount which will be withdrawn
      unchecked { amount++; }
      // Cleanup stakedAssets for the current tokenId
      stakedCreatures[tokenIds[i]] = address(0);
      unchecked { i++; }
    }

    unchecked { userInfo[msg.sender].stakedCreatureCount -= amount; }
    emit Withdrawn(msg.sender, amount, tokenIds, 1);
  }

  /// @notice When paused, staking will be disabled but withdraw won't be
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice When unpaused, staking will be re-enabled
  function unpause() external onlyOwner {
    _unpause();
  }

  /// @notice enables an address to pause token
  /// @param controller the address to enable
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /// @notice disables an address to pause token
  /// @param controller the address to disbale
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

  /// @notice Retrieves pending reward of sender
  function getReward() public nonReentrant {
    uint256 reward = pending(msg.sender) * 1e18;
    if (reward > 0) {
      userInfo[msg.sender].pendingRewards = 0;
      userInfo[msg.sender].lastUpdate = block.timestamp;
      rewardsToken.mint(msg.sender, reward);
      emit RewardPaid(msg.sender, reward);
    }
  }

  modifier updateReward(address account) {
    userInfo[account].pendingRewards = pending(account);
    userInfo[account].lastUpdate = block.timestamp;
    _;
  }

  event Staked(address indexed user, uint256 amount, uint256[] tokenIds, uint nftType);
  event Withdrawn(address indexed user, uint256 amount, uint256[] tokenIds, uint nftType);
  event RewardPaid(address indexed user, uint256 reward);
}