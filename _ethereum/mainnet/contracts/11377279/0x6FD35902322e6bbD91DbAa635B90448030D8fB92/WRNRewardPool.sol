// SPDX-License-Identifier: MIT
import "./Math.sol";
import "./ERC20PresetMinterPauser.sol";
import "./LockUpPool.sol";

pragma solidity ^0.7.1;

contract WRNRewardPool is LockUpPool {
  using SafeMath for uint256;
  using SafeERC20 for ERC20PresetMinterPauserUpgradeSafe;

  ERC20PresetMinterPauserUpgradeSafe public WRNToken; // WRN Reward Token

  // NOTE: didn't use actual constant variable just in case we may chage it on upgrades
  uint256 public REWARD_START_BLOCK;
  uint256 public REWARD_END_BLOCK;
  uint256 public REWARD_EARLY_BONUS_END_BLOCK;
  uint256 public REWARD_PER_BLOCK;
  uint8 public REWARD_EARLY_BONUS_BOOST;

  uint16 public totalMultiplier;
  struct WRNStats {
    uint8 multiplier; // For WRN token distribution
    uint256 accWRNPerShare;
    uint256 lastRewardBlock;
  }

  struct UserWRNReward {
    uint256 claimed;
    uint256 debt;
  }

  // Token => WRNStats
  mapping (address => WRNStats) public wrnStats;

  // Token => Account => UserWRNReward
  mapping (address => mapping (address => UserWRNReward)) public userWRNRewards;

  event PoolAdded(address indexed tokenAddress, uint8 multiplier, uint256 timestamp);
  event WRNMinted(address indexed tokenAddress, uint256 amount, uint256 timestamp);
  event WRNClaimed(address indexed tokenAddress, address indexed account, uint256 amount, uint256 timestamp);

  function initialize(address WRNAddress, uint256 rewardStartBlock, uint256 rewardBlocks, uint256 bonusBlocks) public initializer {
    require(bonusBlocks <= rewardBlocks, 'INVALID_PARAM');

    LockUpPool.initialize();

    WRNToken = ERC20PresetMinterPauserUpgradeSafe(WRNAddress);

    // Total of 1M WRN tokens will be distributed for 4 years
    //  - 0.1 WRN per block by default
    //  - 0.5 WRN per block for beta users (early participants)
    REWARD_START_BLOCK = rewardStartBlock;
    REWARD_PER_BLOCK = 1e17; // 0.1 WRN
    REWARD_END_BLOCK = REWARD_START_BLOCK.add(rewardBlocks); // 8.8M blocks (appx 4 years and 3 months)

    // 5x distribution for the first 500k blocks (appx 3 months)
    REWARD_EARLY_BONUS_END_BLOCK = REWARD_START_BLOCK.add(bonusBlocks);
    REWARD_EARLY_BONUS_BOOST = 5;
  }

  // MARK: - Overiiding LockUpPool

  function addLockUpRewardPool(address tokenAddress, uint8 multiplier, uint256 maxLockUpLimit, bool shouldUpdate) external onlyOwner {
    require(multiplier >= 0, 'INVALID_MULTIPLIER');

    if(shouldUpdate) {
      // NOTE: This could fail with out-of-gas if too many tokens are added.
      // If this fails, the owner MUST update all pools manually
      //
      // Adding a new pool without updating other existing pools can cause
      // a smaller WRN reward than it should be (both pending & claimable value) because
      // `pendingWRN` value becomes smaller with a samller `accWRNPerShare` (= with a bigger `totalMultiplier`).
      // We should save the old `accWRNPerShare` (calculated with the old, smaller `totalMultiplier`)
      // for every pool to prevent this issue.
      updateAllPools();
    }

    addLockUpPool(tokenAddress, maxLockUpLimit);

    wrnStats[tokenAddress].multiplier = multiplier;
    totalMultiplier = totalMultiplier + multiplier;

    emit PoolAdded(tokenAddress, multiplier, block.timestamp);
  }

  function updatePoolMultiplier(address tokenAddress, uint8 multiplier, bool shouldUpdate) external onlyOwner {
    require(multiplier >= 0, 'INVALID_MULTIPLIER');

    if(shouldUpdate) {
      // NOTE: This could fail with out-of-gas if too many tokens are added.
      // If this fails, the owner MUST update all pools manually
      updateAllPools();
    } else if (wrnStats[tokenAddress].multiplier > multiplier) {
      // Decreasing multiplier shouldn't be allowed without `updateAllPools` calls because
      // users can temporarily withdraw a bigger WRN reward than they actually have
      // (caused by smaller `totalMultiplier` => bigger `accWRNPerShare`)

      revert('UPDATE_ALL_REQUIRED');
    }

    totalMultiplier = totalMultiplier - wrnStats[tokenAddress].multiplier + multiplier;
    wrnStats[tokenAddress].multiplier = multiplier;
  }

  function _updateDebt(address tokenAddress, address account) private {
    userWRNRewards[tokenAddress][account].debt = wrnStats[tokenAddress].accWRNPerShare
      .mul(userLockUps[tokenAddress][account].effectiveTotal).div(1e18);
  }

  function doLockUp(address tokenAddress, uint256 amount, uint8 durationInMonths) public override {
    // Should claim WRN before exit, otherwise `pendingWRN` will become zero afterwards
    claimWRN(tokenAddress);

    super.doLockUp(tokenAddress, amount, durationInMonths);

    // shouldn't get the bonus that's already accumulated before the user joined
    _updateDebt(tokenAddress, msg.sender);
  }

  function exit(address tokenAddress, uint256 lockUpIndex, bool force) public override {
    // Should claim WRN before exit, otherwise `pendingWRN` will become zero afterwards
    claimWRN(tokenAddress);

    super.exit(tokenAddress, lockUpIndex, force);

    _updateDebt(tokenAddress, msg.sender);
  }

  // Return WRN per block over the given from to to block.
  function _getWRNPerBlock(uint256 from, uint256 to) private view returns (uint256) {
    if (to < REWARD_START_BLOCK || from > REWARD_END_BLOCK) { // Reward not started or finished
      return 0;
    }
    if (from < REWARD_START_BLOCK) {
      from = REWARD_START_BLOCK;
    }
    if (to > REWARD_END_BLOCK) {
      to = REWARD_END_BLOCK;
    }

    if (to <= REWARD_EARLY_BONUS_END_BLOCK) { // Bonus period
      return to.sub(from).mul(REWARD_EARLY_BONUS_BOOST).mul(REWARD_PER_BLOCK);
    } else if (from <= REWARD_EARLY_BONUS_END_BLOCK && to > REWARD_EARLY_BONUS_END_BLOCK) { // Partial bonus period
      return REWARD_EARLY_BONUS_END_BLOCK.sub(from).mul(REWARD_EARLY_BONUS_BOOST).mul(REWARD_PER_BLOCK).add(
        to.sub(REWARD_EARLY_BONUS_END_BLOCK).mul(REWARD_PER_BLOCK)
      );
    } else { // After bonus period (from > REWARD_EARLY_BONUS_END_BLOCK)
      return to.sub(from).mul(REWARD_PER_BLOCK);
    }
  }

  // Update all pools
  // NOTE: This could fail with out-of-gas if too many tokens are added
  function updateAllPools() public {
    uint256 length = pools.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      updatePool(pools[pid]);
    }
  }

  function updatePool(address tokenAddress) public _checkPoolExists(tokenAddress) {
    WRNStats storage wrnStat = wrnStats[tokenAddress];
    if (block.number <= wrnStat.lastRewardBlock) {
      return;
    }

    TokenStats storage tokenStat = tokenStats[tokenAddress];
    uint256 wrnToMint = _getAccWRNTillNow(tokenAddress);

    if (wrnStat.lastRewardBlock != 0 && tokenStat.effectiveTotalLockUp > 0 && wrnToMint > 0) {
      WRNToken.mint(fundAddress, wrnToMint.div(9)); // 10% dev pool (120,000 / (1,080,000 + 120,000) = 10%)
      WRNToken.mint(address(this), wrnToMint);
      wrnStat.accWRNPerShare = wrnStat.accWRNPerShare.add(
        wrnToMint.mul(1e18).div(tokenStat.effectiveTotalLockUp)
      );

      emit WRNMinted(tokenAddress, wrnToMint, block.timestamp);
    }

    wrnStat.lastRewardBlock = block.number;
  }

  function _getAccWRNTillNow(address tokenAddress) private view returns (uint256) {
    WRNStats storage wrnStat = wrnStats[tokenAddress];

    return _getWRNPerBlock(wrnStat.lastRewardBlock, block.number)
      .mul(wrnStat.multiplier)
      .div(totalMultiplier);
  }

  function pendingWRN(address tokenAddress) public view returns (uint256) {
    TokenStats storage tokenStat = tokenStats[tokenAddress];
    WRNStats storage wrnStat = wrnStats[tokenAddress];
    UserWRNReward storage userWRNReward = userWRNRewards[tokenAddress][msg.sender];

    uint256 accWRNPerShare = wrnStat.accWRNPerShare;
    if (block.number > wrnStat.lastRewardBlock && tokenStat.effectiveTotalLockUp != 0) {
      uint256 accWRNTillNow = _getAccWRNTillNow(tokenAddress);
      accWRNPerShare = accWRNPerShare.add(
        accWRNTillNow.mul(1e18).div(tokenStat.effectiveTotalLockUp)
      );
    }

    // NOTE: it doesn't subtract `userWRNReward.claimed` as it's already included in `userWRNReward.debt`
    return userLockUps[tokenAddress][msg.sender].effectiveTotal
      .mul(accWRNPerShare)
      .div(1e18)
      .sub(userWRNReward.debt);
  }

  function claimWRN(address tokenAddress) public {
    updatePool(tokenAddress);

    uint256 amount = pendingWRN(tokenAddress);
    if (amount == 0) {
      return;
    }

    UserWRNReward storage userWRNReward = userWRNRewards[tokenAddress][msg.sender];

    userWRNReward.claimed = userWRNReward.claimed.add(amount);
    _updateDebt(tokenAddress, msg.sender);

    WRNToken.safeTransfer(msg.sender, amount);

    emit WRNClaimed(tokenAddress, msg.sender, amount, block.timestamp);
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}
