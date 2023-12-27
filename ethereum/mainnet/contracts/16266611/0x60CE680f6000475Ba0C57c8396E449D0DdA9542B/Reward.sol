// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./ERC20.sol";
import "./IERC20.sol";

import "./IReward.sol";
import "./IAdoption.sol";
import "./IRuno.sol";
import "./Type.sol";

contract Reward is IReward, AccessControl, ReentrancyGuard {
  bytes32 public constant OWNER_ROLE = keccak256("OWNER");
  bytes32 public constant TOKEN_ROLE = keccak256("TOKEN");
  uint256 public constant TOKEN_FETCH_LIMIT = 100;

  // addresses
  address private _owner;
  address private _rewardProvider;
  address private _runoAddress;
  IERC20 public ainAddress;

  mapping(uint256 => uint256) public runStartAt;
  mapping(uint256 => uint256) public lastClaimedAt;

  /**
   * Rewards
   */
  uint256 public rewardStartAt;
  uint256 private lastMonth;
  mapping(uint256 => uint256) public rewardFactorByTier;
  mapping(uint256 => uint256) public dailyRewardsByMonth;
  mapping(uint256 => uint256) public claimedReward;

  constructor(
    address rewardProvider_,
    address runoAddress_,
    address ainAddress_,
    uint256 rewardStartAt_
  ) {
    require(rewardProvider_ != address(0), "Reward: invalid reward address");
    require(runoAddress_ != address(0), "Reward: invalid Runo address");
    require(ainAddress_ != address(0), "Reward: invalid ainAddress");
    _grantRole(OWNER_ROLE, _msgSender());
    _setRoleAdmin(TOKEN_ROLE, OWNER_ROLE);

    _rewardProvider = rewardProvider_;
    _runoAddress = runoAddress_;
    // ERC20 AIN token address
    ainAddress = IERC20(ainAddress_);
    rewardStartAt = rewardStartAt_;

    rewardFactorByTier[0] = 1;
    rewardFactorByTier[1] = 5;
    rewardFactorByTier[2] = 15;

    lastMonth = 4;
    dailyRewardsByMonth[0] = 28.57 ether; // 'ether' means 10^18
    dailyRewardsByMonth[1] = 27.99 ether;
    dailyRewardsByMonth[2] = 27.32 ether;
    dailyRewardsByMonth[3] = 26.56 ether;
    dailyRewardsByMonth[4] = 25.70 ether;
  }

  function supportsInterface(
    bytes4 interfaceId_
  ) public view override returns (bool) {
    return interfaceId_ == type(IReward).interfaceId ||
        super.supportsInterface(interfaceId_);
  }

  function getRewardStartAt(
  ) public view returns (uint256) {
    return rewardStartAt;
  }

  function setRewardStartAt(
    uint256 rewardStartAt_
  ) public onlyRole(OWNER_ROLE) {
    rewardStartAt = rewardStartAt_;
  }

  function getTokenInfo(
    uint256[] memory tokenIds_
  ) public view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
    require(tokenIds_.length <= TOKEN_FETCH_LIMIT);
    uint256[] memory startAt = new uint256[](tokenIds_.length);
    uint256[] memory claimed = new uint256[](tokenIds_.length);
    uint256[] memory claimedAt = new uint256[](tokenIds_.length);
    for (uint256 i = 0; i < tokenIds_.length; i++) {
      startAt[i] = runStartAt[tokenIds_[i]];
      claimed[i] = claimedReward[tokenIds_[i]];
      claimedAt[i] = lastClaimedAt[tokenIds_[i]];
    }
    return (startAt, claimed, claimedAt);
  }

  /**
   * @dev Run Runo token with token ID 
   * @param tokenIds_ array of tokenId
   */
  function run(
    uint256[] memory tokenIds_
  ) public {
    IRuno runo = IRuno(_runoAddress);
    address sender = _msgSender();
    for (uint256 i = 0; i < tokenIds_.length; i++) {
      require(runo.ownerOf(tokenIds_[i]) == sender, "Runo: invalid owner");
      // XXX: if token is not in IDLE state, just continue?
      require(!runo.isTokenRunning(tokenIds_[i]), "Runo: not idle state");
      runo.toggleRunning(tokenIds_[i]);
      runStartAt[tokenIds_[i]] = block.timestamp;
    }
  }

  /**
   * @dev Stop Runo token with token ID 
   * @param tokenIds_ array of tokenId
   */
  function stop(
    uint256[] memory tokenIds_
  ) public {
    IRuno runo = IRuno(_runoAddress);
    for (uint256 i = 0; i < tokenIds_.length; i++) {
      require(runo.ownerOf(tokenIds_[i]) == _msgSender(), "Runo: invalid owner");
      // XXX: if token is not in RUNNING state, just continue?
      require(runo.isTokenRunning(tokenIds_[i]), "Runo: not running state");
      uint256 amount = getClaimableRewards(tokenIds_[i]);
      if (amount != 0) {
        claimReward(tokenIds_[i]);
      }
      runo.toggleRunning(tokenIds_[i]);
      runStartAt[tokenIds_[i]] = 0;
      lastClaimedAt[tokenIds_[i]] = 0;
    }
  }

  /**
   * @dev Get claimable rewards
   * @param tokenId_ ID of token
   */
  function getClaimableRewards(
    uint256 tokenId_
  ) public view returns (uint256) {
    if (block.timestamp < rewardStartAt) { return 0; }
    IRuno runo = IRuno(_runoAddress);
    require(runo.ownerOf(tokenId_) == _msgSender(), "Reward: not owner");
    uint256 tier = runo.getTokenTier(tokenId_);
    require(runo.isTokenRunning(tokenId_), "Runo: not running state");
    uint256 startAt = runStartAt[tokenId_];
    if (lastClaimedAt[tokenId_] != 0) {
      startAt = (lastClaimedAt[tokenId_] / 86400) * 86400;
    }
    if (startAt == block.timestamp) { return 0; }
    uint256 fromMonth = 0;
    if (startAt > rewardStartAt) {
      fromMonth = (startAt - rewardStartAt) / 2592000;
    }
    uint256 toMonth = (block.timestamp - rewardStartAt) / 2592000 + 1;
    uint256 total = 0;
    for (uint256 i = fromMonth; i < toMonth; i++) {
      if (dailyRewardsByMonth[i] == 0) { continue; }
      uint256 from = rewardStartAt + (2592000 * i);
      uint256 to = rewardStartAt + (2592000 * (i + 1));
      if (from >= block.timestamp) { break; }
      if (startAt < to && startAt >= from) {
        from = startAt;
      } 
      if (from < block.timestamp && block.timestamp < to) {
        to = (block.timestamp / 86400) * 86400;
      }
      if (to <= from) { continue; }
      uint256 day = (to - from) / 86400;
      total += dailyRewardsByMonth[i] * day * rewardFactorByTier[tier];
    }
    return total;
  }

  /**
   * @dev Claim rewards
   * @param tokenId_ ID of token
   */
  function claimReward(
    uint256 tokenId_
  ) public payable nonReentrant {
    IRuno runo = IRuno(_runoAddress);
    require(runo.ownerOf(tokenId_) == _msgSender(), "Reward: not owner");
    uint256 amount = getClaimableRewards(tokenId_);
    require(amount != 0, "Reward: cannot claim zero");
    ainAddress.transferFrom(_rewardProvider, _msgSender(), amount);
    claimedReward[tokenId_] += amount;
    lastClaimedAt[tokenId_] = block.timestamp;
  }

  /**
   * @dev Claim all rewards
   * @param tokenIds_ array of token ID
   */
  function claimRewardAll(
    uint256[] memory tokenIds_
  ) public payable {
    for (uint256 i = 0; i < tokenIds_.length; i++) {
      claimReward(tokenIds_[i]);
    }
  }

  /**
   * @dev Set daily reward for month 
   * @param month_ number of months from start
   * @param reward_ daily reward for month
   */
  function setDailyRewardByMonth(
    uint256 month_,
    uint256 reward_
  ) public onlyRole(OWNER_ROLE) {
    require(month_ <= lastMonth + 1, "Reward: invalid month");
    if (month_ == lastMonth + 1) {
      lastMonth = month_;
    }
    dailyRewardsByMonth[month_] = reward_;
  }

  /**
   * @dev Get reward table 
   */
  function getCurrentRewardTable(
  ) public view onlyRole(OWNER_ROLE) returns (uint256[] memory) {
    uint256[] memory table = new uint256[](lastMonth + 1);
    for (uint256 i = 0; i <= lastMonth; i++) {
      table[i] = dailyRewardsByMonth[i];
    }
    return (table);
  }

  function initClaimed(
    uint256 tokenId_
  ) public onlyRole(TOKEN_ROLE) {
    claimedReward[tokenId_] = 0;
  }

  function destroy(
    address payable to_
  ) public onlyRole(OWNER_ROLE) {
    selfdestruct(to_);
  }
}