//  _________  _________   _______  __________
// /__     __\|    _____) /   .   \/    _____/
//    |___|   |___|\____\/___/ \___\________\

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC20Upgradeable.sol";

import "./ITRAC.sol";
import "./ITRACAssets.sol";

contract CREDIT is ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

  uint128 constant private REWARD_PER_SECOND = 8 ether / uint128(60 * 60 * 24);
  uint128 constant private REWARD_BACKPACK_PER_SECOND = 10 ether / uint128(60 * 60 * 24);

  bool public claimPaused;
  uint128 public globalRewardsClaimed;

  struct RewardSummary {
    uint16[] tokens;
    uint128 claimableReward;
    uint128 totalClaimed;
    uint48 lastClaimTimestamp;
    uint128 globalRewardsClaimed;
    uint256 balance;
  }

  struct OwnerRewards { uint128 totalClaimed; uint48 lastClaim; }
  mapping(address => OwnerRewards) public ownerRewards;
  ITRAC private _trac;
  ITRACAssets private _items;
  
  event ClaimReward(address owner, uint128 reward);

  function initialize(address trac, address community) public initializer {
    __ERC20_init_unchained("TRAC CREDIT", "CREDIT");
    __Ownable_init_unchained();
    __ReentrancyGuard_init_unchained();

    _mint(address(this), 355555556 ether);
    _mint(community, 88888888 ether);

    _trac = ITRAC(trac);
  }

  function toggleClaims() public onlyOwner {
    claimPaused = !claimPaused;
  }

  struct Seconds { uint128 base; uint128 locker; uint128 backpack; uint128 all; }

  function summaryOf(address account) external view returns (RewardSummary memory summary) {
    ITRAC.TokenTime[] memory tokenTimes = _trac.tokenTimesOf(account);
    uint16[] memory tokens = new uint16[](tokenTimes.length);
    uint48 blockTimestamp = uint48(block.timestamp);
    uint48 lastClaim = ownerRewards[account].lastClaim;
    ITRACAssets.Purchases memory purchases = _items.getPurchases(account);
    uint48 backpack; uint48 locker; uint48 trac;
    Seconds memory sec;

    for (uint16 i; i < tokenTimes.length; i++) {
      if (tokenTimes[i].token != 0) {
        tokens[i] = tokenTimes[i].token;

        // Purchase times
        trac = lastClaim > trac ? lastClaim : tokenTimes[i].timestamp;
        backpack = i < purchases.backpacks.length ? purchases.backpacks[i] : blockTimestamp;
        locker = i < purchases.lockers.length * 8 ? purchases.lockers[i / 8] : blockTimestamp;

        // Calculate reward seconds                            // (Based on purchase order)
        if (trac <= backpack && backpack <= locker) {          // TRAC > BACKPACK > LOCKER
          sec.base += backpack - trac;
          sec.backpack += locker - backpack;
          sec.all += blockTimestamp - locker;
        } else if (trac <= locker && locker <= backpack) {     // TRAC > LOCKER > BACKPACK
          sec.base += locker - trac;
          sec.locker += backpack - locker;
          sec.all += blockTimestamp - backpack;
        } else if (backpack <= trac && trac <= locker) {       // BACKPACK > TRAC > LOCKER
          sec.backpack += locker - trac;
          sec.all += blockTimestamp - locker;
        } else if (locker <= trac && trac <= backpack) {       // LOCKER > TRAC > BACKPACK
          sec.locker += backpack - trac;
          sec.all += blockTimestamp - backpack;
        } else {                                               // * > TRAC
          sec.all += blockTimestamp - trac;
        }
      }
    }

    // Sum reward
    uint128 reward =
      (sec.base * REWARD_PER_SECOND) +
      (sec.locker * REWARD_PER_SECOND) + ((sec.locker * REWARD_PER_SECOND) / 2) +
      (sec.backpack * REWARD_BACKPACK_PER_SECOND) +
      (sec.all * REWARD_BACKPACK_PER_SECOND) + ((sec.all * REWARD_BACKPACK_PER_SECOND) / 2);

    // Store summary response
    summary = RewardSummary(
      tokens,
      reward,
      ownerRewards[account].totalClaimed,
      lastClaim,
      globalRewardsClaimed,
      balanceOf(account)
    );
  }

  function claimRewards(uint16[] calldata tokens) external nonReentrant {
    require(tx.origin == msg.sender, "eos only");
    require(!claimPaused, "claim paused");
    require(tokens.length > 0, "empty tokens");

    uint48 lastClaim = ownerRewards[msg.sender].lastClaim;
    ITRAC.OwnerTime[] memory ownerTimes = _trac.ownerTimesOf(tokens);
    uint48 blockTimestamp = uint48(block.timestamp);
    ITRACAssets.Purchases memory purchases = _items.getPurchases(msg.sender);
    uint48 backpack; uint48 locker; uint48 trac;
    Seconds memory sec;

    uint16 prevTokenId;
    for (uint16 i; i < ownerTimes.length; i++) {
      require(tokens[i] > prevTokenId, "out of order"); // prevent duplicates
      require(ownerTimes[i].owner == msg.sender, "not owner");

      // Purchase times
      trac = lastClaim > trac ? lastClaim : ownerTimes[i].timestamp;
      backpack = i < purchases.backpacks.length ? purchases.backpacks[i] : blockTimestamp;
      locker = i < purchases.lockers.length * 8 ? purchases.lockers[i / 8] : blockTimestamp;

      // Calculate reward seconds                            // (Based on purchase order)
      if (trac <= backpack && backpack <= locker) {          // TRAC > BACKPACK > LOCKER
        sec.base += backpack - trac;
        sec.backpack += locker - backpack;
        sec.all += blockTimestamp - locker;
      } else if (trac <= locker && locker <= backpack) {     // TRAC > LOCKER > BACKPACK
        sec.base += locker - trac;
        sec.locker += backpack - locker;
        sec.all += blockTimestamp - backpack;
      } else if (backpack <= trac && trac <= locker) {       // BACKPACK > TRAC > LOCKER
        sec.backpack += locker - trac;
        sec.all += blockTimestamp - locker;
      } else if (locker <= trac && trac <= backpack) {       // LOCKER > TRAC > BACKPACK
        sec.locker += backpack - trac;
        sec.all += blockTimestamp - backpack;
      } else {                                               // * > TRAC
        sec.all += blockTimestamp - trac;
      }
    }

    // Sum reward
    uint128 reward =
      (sec.base * REWARD_PER_SECOND) +
      (sec.locker * REWARD_PER_SECOND) + ((sec.locker * REWARD_PER_SECOND) / 2) +
      (sec.backpack * REWARD_BACKPACK_PER_SECOND) +
      (sec.all * REWARD_BACKPACK_PER_SECOND) + ((sec.all * REWARD_BACKPACK_PER_SECOND) / 2);

    ownerRewards[msg.sender] = OwnerRewards(
      ownerRewards[msg.sender].totalClaimed + reward,
      blockTimestamp
    );

    globalRewardsClaimed += reward;
    emit ClaimReward(msg.sender, reward);
    _transfer(address(this), msg.sender, reward);
  }

  function burn(address account, uint256 amount) external nonReentrant {
    require(msg.sender == address(_trac) || msg.sender == address(_items), "only trac");
    _burn(account, amount);
  }

  function setAssetsAddress(address assets) external onlyOwner {
    _items = ITRACAssets(assets);
  }
}
