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
import "./ICyber.sol";

/// @title Cyberfrogz: Staking
/// @author @ryeshrimp

contract CyberFrogzStaking is Initializable, ERC721Holder, ReentrancyGuardUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    
  uint32 public constant SECONDS_IN_DAY = 1 days;

  ICyber public rewardsToken;
  IERC721Enumerable public cyberFrogzAddress;

  struct UserInfo {
    uint256 stakedCount;
    uint256 pendingRewards;
    uint256 lastUpdate;
  }

  mapping(address => bool) controllers;

  mapping(address => UserInfo) public userInfo;
  mapping(uint256 => address) public staked;

  uint256 public rewardsPerDay;

  function initialize(
    address _cyberFrogzAddress,
    address _rewardsToken,
    uint256 _rewardsPerDay
  ) public initializer {

    __Ownable_init();
    __Pausable_init();

    cyberFrogzAddress = IERC721Enumerable(_cyberFrogzAddress);
    rewardsToken = ICyber(_rewardsToken);
    rewardsPerDay = _rewardsPerDay;

    controllers[msg.sender] = true;
  }

  /// @notice Total amount of staked assets
  function balanceOf(address owner) public view virtual returns (uint256) {
    return userInfo[owner].stakedCount;
  }

  /// @notice Calculates live pending rewards of owner
  /// @param account the address of owner
  function pending(address account) public view returns (uint256) {
    return userInfo[account].pendingRewards + (((block.timestamp - userInfo[account].lastUpdate) / SECONDS_IN_DAY) * (userInfo[account].stakedCount*rewardsPerDay));
  }

  /// @notice Returns IDs of staked assets by owner
  /// @param account the address of owner
  function stakedByOwner(address account) public view returns (uint256[] memory) {
    uint256 supply = cyberFrogzAddress.totalSupply();
    uint256[] memory tmp = new uint256[](supply);

    uint256 index;
    for(uint tokenId = 1; tokenId <= supply; tokenId++) {
      if (staked[tokenId] == account) {
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

  /// @notice Set cyberfrogz or rewards address
  /// @param _mode A number corresponding to the token type
  /// 1 - cyberFrogzAddress
  /// 3 - rewardsToken
  function setAddresses(uint8 _mode, address _address) external onlyOwner {
    if (_mode == 1) cyberFrogzAddress = IERC721Enumerable(_address);
    else if (_mode == 2) rewardsToken = ICyber(_address);
    else revert("setAddresses: WRONG_MODE");
  }

  /// @notice Set rewards amount for NFTs
  function setRewards(uint256 _amount) external onlyOwner {
    rewardsPerDay = _amount;
  }

  /// @notice Stakes user's NFTs
  /// @param tokenIds The tokenIds of the NFTs which will be staked
  function stake(uint256[] memory tokenIds) external nonReentrant whenNotPaused updateReward(msg.sender) {
    require(tokenIds.length > 0, "No tokenIds provided");

    uint256 amount;
    for (uint256 i; i < tokenIds.length;) {
      // Transfer user's NFTs to the staking contract
      cyberFrogzAddress.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
      // Increment the amount which will be staked
      unchecked { amount++; }
      // Save who is the staker/depositor of the token
      staked[tokenIds[i]] = msg.sender;
      unchecked { i++; }
    }

    unchecked { userInfo[msg.sender].stakedCount += amount; }
    emit Staked(msg.sender, amount, tokenIds);
  }


  /// @notice Withdraws staked NFTs
  /// @param tokenIds The tokenIds of the NFTs which will be withdrawn
  function withdraw(uint256[] memory tokenIds) external nonReentrant updateReward(msg.sender) {
    require(tokenIds.length > 0, "No tokenIds provided");

    uint256 amount;
    for (uint256 i; i < tokenIds.length;) {
      // Check if the user who withdraws is the owner
      require(staked[tokenIds[i]] == msg.sender, "Not the staker of the token");
      // Transfer NFTs back to the owner
      cyberFrogzAddress.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
      // Increment the amount which will be withdrawn
      amount++;
      // Cleanup stakedAssets and paused info for the current tokenId
      staked[tokenIds[i]] = address(0);
      unchecked { i++; }
    }

    unchecked { userInfo[msg.sender].stakedCount -= amount; }
    emit Withdrawn(msg.sender, amount, tokenIds);
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

  event Staked(address indexed user, uint256 amount, uint256[] tokenIds);
  event Withdrawn(address indexed user, uint256 amount, uint256[] tokenIds);
  event RewardPaid(address indexed user, uint256 reward);
}