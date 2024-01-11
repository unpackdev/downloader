// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./ITiny721.sol";

/*
  It saves bytecode to revert on custom errors instead of using require
  statements. We are just declaring these errors for reverting with upon various
  conditions later in this contract.
*/
error CannotAddPoolWithInvalidId();
error CannotStakeAfterDeadline();
error CannotStakeInactivePool();
error CannotStakeUnownedItem();
error CannotStakeTimeLockedItem();
error CannotWithdrawUnownedItem();
error CannotWithdrawTimeLockedItem();
error CannotWithdrawUnstakedItem();
error SweepingTransferFailed();
error EmptyTokenIdsArray();

/**
  @title A simple staking contract for transfer-locking `Tiny721` items in
    exchange for tokens.
  @author Tim Clancy
  @author Rostislav Khlebnikov
  @author 0xthrpw

  This staking contract disburses tokens from its internal reservoir to those
  who stake `Tiny721` items, at a fixed rate of token per item independent of
  the number of items staked. It supports defining multiple time-locked pools
  with different rates.

  March 7th, 2022.
*/
contract ImpostorsStaker is
  Ownable, ReentrancyGuard
{
  using SafeERC20 for IERC20;

  /// The name of this Staker.
  string public name;

  /// The token to disburse.
  address public immutable token;

  /**
    This struct is used to define information regarding a particular pool that
    the user may choose to stake their items against.

    @param item The address of the item contract that is allowed to be staked in
      this pool.
    @param lockedTokensPerSecond The amount of token that each item staked in
      this pool earns each second while it is locked during the `lockDuration`.
    @param unlockedTokensPerSecond The amount of token that each item staked in
      this pool earns each second while it is unlocked and available for
      withdrawal.
    @param lockDuration The amount of time in seconds wherein this pool requires
      that the asset remain time-locked and unavailable to withdraw. Once the
      item has been staked for `lockDuration` seconds, the item may be
      withdrawn from the pool and the number of tokens earned changes to the
      `unlockedTokensPerSecond` rate.
    @param deadline Determines the time after which no more stakes are accepted
  */
  struct Pool {
    address item;
    uint256 lockedTokensPerSecond;
    uint256 unlockedTokensPerSecond;
    uint256 lockDuration;
    uint256 deadline;
  }

  /// A mapping with to look up information for each specific pool.
  mapping ( uint256 => Pool ) public pools;

  /**
    This struct is used to define information surrounding the status of a
    particular item in this staking contract.

    @param stakedPool The ID of the pool where this item is currently staked. An
      ID of zero indicates that the item is not staked to any pool.
    @param stakedAt The time when this item was last staked in the pool. This is
      used to control earning rates due to time-locking in a pool.
    @param tokenClaimed The number of tokens claimed by this item so far. This
      is used to support partial claiming of earned tokens during a pool's full
      `_lockDuration`.
  */
  struct ItemStatus {
    uint256 stakedPool;
    uint256 stakedAt;
    uint256 tokenClaimed;
  }

  /**
    A double mapping relating a `Tiny721` item address and the ID of a specific
    token to details about its status in the pool where it is currently staked.
  */
  mapping ( address => mapping ( uint256 => ItemStatus )) public itemStatuses;

  /**
    This struct is used to define information regarding a particular caller's
    position in a particular pool.

    @param stakedItems An array of all token IDs staked by a caller in this
      particular position.
    @param tokenPaid The value of the caller's total earning that has been paid
      out in this position.
  */
  struct Position {
    uint256[] stakedItems;
    uint256 tokenPaid;
  }

  /**
    A double mapping relating a particular pool ID to and the address of a
    caller to information about the caller's `Position` in that pool.
  */
  mapping ( uint256 => mapping ( address => Position )) public positions;

  /// The total amount of the disbursed `token` ever emitted by this Staker.
  uint256 public totalTokenDisbursed;

  /**
    An event tracking a claim of tokens for some pools from this staker.

    @param timestamp The block timestamp when this event was emitted.
    @param caller The caller who triggered the claim.
    @param poolIds The array of pool IDs where tokens were claimed from.
    @param amount The amount of `token` claimed by the `caller` in this event.
  */
  event Claim (
    uint256 timestamp,
    address indexed caller,
    uint256[] poolIds,
    uint256 amount
  );

  /**
    An event tracking a staking of the specified `tokenIds` into a specific pool
    of this staker.

    @param timestamp The block timestamp when this event was emitted.
    @param caller The caller who triggered the claim.
    @param poolId The ID of the pool that tokens were staked into.
    @param item The address of the item smart contract with the token IDs
      specified in `tokenIds`.
    @param tokenIds The IDs of the tokens staked into this pool.
  */
  event Stake (
    uint256 timestamp,
    address indexed caller,
    uint256 poolId,
    address indexed item,
    uint256[] tokenIds
  );

  /**
    An event tracking a withdrawal of the specified `tokenIds` from a specific
    pool of this staker.

    @param timestamp The block timestamp when this event was emitted.
    @param caller The caller who triggered the claim.
    @param poolId The ID of the pool that tokens were withdrawn from.
    @param item The address of the item smart contract with the token IDs
      specified in `tokenIds`.
    @param tokenIds The IDs of the tokens withdrawn from this pool.
  */
  event Withdraw (
    uint256 timestamp,
    address indexed caller,
    uint256 poolId,
    address indexed item,
    uint256[] tokenIds
  );

  /**
    Construct a new Staker by providing it a name and the token to disburse.

    @param _name The name of the Staker contract.
    @param _token The token to reward stakers in this contract with.
  */
  constructor (
    string memory _name,
    address _token
  ) {
    name = _name;
    token = _token;
  }

  function getPosition(uint256 _id, address _addr) public view returns (uint256[] memory, uint256){
    Position memory p = positions[_id][_addr];
    return (p.stakedItems, p.tokenPaid);
  }

  function getItemsPosition(uint256 _id, address _addr) public view returns (uint256[] memory){
    Position memory p = positions[_id][_addr];
    return p.stakedItems;
  }

  /**
    Allow the contract owner to add a new staking `Pool` to the Staker or
    overwrite the configuration of an existing one.

    @param _id The ID of the `Pool` to add or update.
    @param _item The address of the item contract that is staked in this pool.
    @param _lockedTokensPerSecond The amount of token that each item staked in
      this pool earns each second while it is locked during the `lockDuration`.
    @param _unlockedTokensPerSecond The amount of token that each item staked in
      this pool earns each second while it is unlocked and available for
      withdrawal.
    @param _lockDuration The amount of time in seconds where this pool requires
      that the asset remain time-locked and unavailable to withdraw. Once the
      item has been staked for `lockDuration` seconds, the item may be
      withdrawn from the pool and the number of tokens earned changes to the
      `unlockedTokensPerSecond` rate.
    @param _deadline The timestamp stakes must be created by, any stakes to
      pool that are attempted after this timestamp will revert.
  */
  function setPool (
    uint256 _id,
    address _item,
    uint256 _lockedTokensPerSecond,
    uint256 _unlockedTokensPerSecond,
    uint256 _lockDuration,
    uint256 _deadline
  ) external onlyOwner {

    // There may be no pool with ID of 0.
    if (_id < 1) {
      revert CannotAddPoolWithInvalidId();
    }

    // Update the `Pool` being tracked in the `pools` mapping.
    pools[_id].item = _item;
    pools[_id].lockedTokensPerSecond = _lockedTokensPerSecond;
    pools[_id].unlockedTokensPerSecond = _unlockedTokensPerSecond;
    pools[_id].lockDuration = _lockDuration;
    pools[_id].deadline = _deadline;
  }

  /**
    Claim all of the caller's pending tokens from the specified pools.

    @param _poolIds The IDs of the pools to claim pending token rewards from.
  */
  function claim (
    uint256[] memory _poolIds
  ) public nonReentrant {
    uint256 totalClaimAmount;
    for (uint256 poolIndex; poolIndex < _poolIds.length; ++poolIndex) {
      uint256 poolId = _poolIds[poolIndex];
      Pool storage pool = pools[poolId];
      Position storage position = positions[poolId][_msgSender()];

      /*
        Iterate through each item that the caller has staked into this pool. If
        the caller has staked assets, transfer any accrued balance to them.
      */
      for (uint256 i; i < position.stakedItems.length; ++i) {
        uint256 stakedItemId = position.stakedItems[i];

        /*
          Retrieve the status of each staked item and calculate the total amount
          that has been earned by each staked item in this pool.
        */
        ItemStatus storage status = itemStatuses[pool.item][stakedItemId];
        uint256 lockEnds = status.stakedAt + pool.lockDuration;
        uint256 totalEarnings;

        // We are within the unlocked period for this item.
        if (block.timestamp > lockEnds) {
          totalEarnings = pool.lockDuration * pool.lockedTokensPerSecond;
          totalEarnings += (block.timestamp - lockEnds) * pool.unlockedTokensPerSecond;

        // We are within the time-locked period for this item.
        } else {
          totalEarnings = (block.timestamp - status.stakedAt) * pool.lockedTokensPerSecond;
        }

        // Subtract any previously-claimed amount from the total amount earned.
        uint256 tokenClaimed = status.tokenClaimed;
        uint256 unclaimedReward = totalEarnings - tokenClaimed;

        // Update the number of tokens claimed by this item in its present pool.
        status.tokenClaimed = totalEarnings;

        // Update the amount historically claimed by the caller in this pool.
        position.tokenPaid = position.tokenPaid + unclaimedReward;

        // Transfer the unclaimed reward to the user.
        totalClaimAmount = totalClaimAmount + unclaimedReward;
      }
    }

    // Update the total amount of token disbursed by this contract.
    totalTokenDisbursed = totalTokenDisbursed + totalClaimAmount;
    IERC20(token).safeTransfer(
      _msgSender(),
      totalClaimAmount
    );

    // Emit an event.
    emit Claim(block.timestamp, _msgSender(), _poolIds, totalClaimAmount);
  }

  /**
    View to retrieve current pending rewards for a user

    @param _poolIds the pools we are inquiring about
    @param _user the address of the account being queried
  */
  function pendingClaims (
    uint256[] memory _poolIds,
    address _user
  ) external view returns (uint256 totalClaimAmount) {
    for (uint256 poolIndex; poolIndex < _poolIds.length; ++poolIndex) {
      uint256 poolId = _poolIds[poolIndex];
      Pool storage pool = pools[poolId];
      Position storage position = positions[poolId][_user];

      /*
        Iterate through each item that the caller has staked into this pool.
      */
      for (uint256 i = 0; i < position.stakedItems.length; ++i) {
        uint256 stakedItemId = position.stakedItems[i];

        /*
          Retrieve the status of each staked item and calculate the total amount
          that has been earned by each staked item in this pool.
        */
        ItemStatus storage status = itemStatuses[pool.item][stakedItemId];
        uint256 lockEnds = status.stakedAt + pool.lockDuration;
        bool itemUnlocked = block.timestamp > lockEnds;
        uint256 totalEarnings;

        // We are within the unlocked period for this item.
        if (itemUnlocked) {
          totalEarnings = pool.lockDuration * pool.lockedTokensPerSecond;
          uint256 flexibleDuration = block.timestamp - lockEnds;
          totalEarnings += flexibleDuration * pool.unlockedTokensPerSecond;

        // We are within the time-locked period for this item.
        } else {
          uint256 stakeDuration = block.timestamp - status.stakedAt;
          totalEarnings = stakeDuration * pool.lockedTokensPerSecond;
        }

        // Subtract any previously-claimed amount from the total amount earned.
        totalClaimAmount = totalClaimAmount + totalEarnings - status.tokenClaimed;
      }
    }
    return totalClaimAmount;
  }

  /**
    This private helper function converts a number into a single-element array.

    @param _element The element to convert to an array.

    @return The array containing the single `_element`.
  */
  function _asSingletonArray (
    uint256 _element
  ) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = _element;
    return array;
  }

  /**
    Lock some particular token IDs from some particular contract addresses into
    some particular `Pool` of this Staker.

    @param _poolId The ID of the `Pool` to stake items in.
    @param _tokenIds An array of token IDs corresponding to specific tokens in
      the item contract from `Pool` with the ID of `_poolId`.
  */
  function stake (
    uint256 _poolId,
    uint256[] calldata _tokenIds
  ) external  {
    if (_tokenIds.length == 0) {
      revert EmptyTokenIdsArray();
    }

    Pool storage pool = pools[_poolId];

    // Reject stakes for inactive pools.
    if (pool.lockedTokensPerSecond < 1) {
      revert CannotStakeInactivePool();
    }

    // Enforce a deadline on pool entry.
    if (block.timestamp > pool.deadline) {
      revert CannotStakeAfterDeadline();
    }

    // Claim pending tokens.
    claim(_asSingletonArray(_poolId));

    // Stake the caller's items by locking transfer of that item.
    ITiny721 item = ITiny721(pool.item);
    for (uint256 i; i < _tokenIds.length; ++i) {
      uint256 tokenId = _tokenIds[i];

      // Verify that the caller owns the token being locked.
      if (item.ownerOf(tokenId) != _msgSender()) {
        revert CannotStakeUnownedItem();
      }

      /*
        Retrieve the status of each item to see if it is new to the pool, new to
        the staker, or unlocked. In short, we verify that the item is able to be
        staked into this pool.
      */
      ItemStatus storage status = itemStatuses[pool.item][tokenId];
      uint256 lockEnds = status.stakedAt + pool.lockDuration;
      bool itemUnlocked = block.timestamp > lockEnds;

      /*
        Reject requests trying to stake an item that has not completed its lock
        duration. This prevents callers from double-dipping by staking the
        same item to multiple pools.
      */
      if (!itemUnlocked) {
        revert CannotStakeTimeLockedItem();
      }

      /*
        We allow the caller to re-lock their item into a pool without having to
        withdraw it first if it has completed its time lock. To accomodate this,
        we must reset storage regarding the status of the item being staked.
      */
      status.stakedPool = _poolId;
      status.stakedAt = block.timestamp;
      status.tokenClaimed = 0;

      /*
        Update the caller's staked items to add each new item ID to the caller's
        array of staked token IDs if it is not already present as a staked item.
      */
      Position storage position = positions[_poolId][_msgSender()];

      // Check each token ID to see if it is already present as a staked ID.
      bool alreadyStaked = false;
      for (
        uint256 stakedIndex;
        stakedIndex < position.stakedItems.length;
        ++stakedIndex
      ) {
        uint256 stakedId = position.stakedItems[stakedIndex];
        if (tokenId == stakedId) {
          alreadyStaked = true;
          break;
        }
      }

      // If this is truly a newly-staked item, add it to the array.
      if (!alreadyStaked) {
        position.stakedItems.push(tokenId);
      }

      /*
        If the item beingstaked is not already transfer-locked, then lock
        any transfers of the item that has been staked.
      */
      if (!item.transferLocks(tokenId)) {
        item.lockTransfer(tokenId, true);
      }
    }

    // Emit an event.
    emit Stake(block.timestamp, _msgSender(), _poolId, pool.item, _tokenIds);
  }

  /**
    Unlock some particular token IDs from some particular contract addresses
    from some particular `Pool` of this Staker.

    @param _poolId The ID of the `Pool` to unstake items from.
    @param _tokenIds An array of token IDs corresponding to specific tokens in
      the item contract from `Pool` with the ID of `_poolId` that are to be
      unstaked.
  */
  function withdraw (
    uint256 _poolId,
    uint256[] calldata _tokenIds
  ) external {
    Pool storage pool = pools[_poolId];
    Position storage position = positions[_poolId][_msgSender()];

    // Claim pending tokens.
    claim(_asSingletonArray(_poolId));

    // Withdraw the caller's items by unlocking transfer of that item.
    ITiny721 item = ITiny721(pool.item);
    for (uint256 i = 0; i < _tokenIds.length; ++i ) {
      uint256 tokenId = _tokenIds[i];

      // Verify that the caller owns the token being unlocked.
      if (item.ownerOf(tokenId) != _msgSender()) {
        revert CannotWithdrawUnownedItem();
      }

      // Verify that any time lock on withdrawing the item has completed.
      ItemStatus storage status = itemStatuses[pool.item][tokenId];
      uint256 lockEnds = status.stakedAt + pool.lockDuration;
      bool itemUnlocked = block.timestamp > lockEnds;
      if (!itemUnlocked) {
        revert CannotWithdrawTimeLockedItem();
      }

      /*
        Verify that the item was actually staked in this pool. This check
        prevents withdrawing an item from a different pool by using the
        time-lock of this pool.
      */
      if (_poolId != status.stakedPool) {
        revert CannotWithdrawUnstakedItem();
      }

      // Clear storage mapping now that the item is unlocked.
      status.stakedPool = 0;
      status.stakedAt = 0;
      status.tokenClaimed = 0;

      // Check each token ID to find its index.
      for (
        uint256 stakedIndex;
        stakedIndex < position.stakedItems.length;
        ++stakedIndex
      ) {
        uint256 stakedId = position.stakedItems[stakedIndex];
        if (tokenId == stakedId) {

          // Remove the element at the matching index.
          for (
            uint256 r = stakedIndex;
            r < position.stakedItems.length - 1;
            ++r
          ) {
            position.stakedItems[r] = position.stakedItems[r + 1];
          }
          position.stakedItems.pop();
          break;
        }
      }

      // Unlock transfers of the item.
      item.lockTransfer(tokenId, false);
    }

    // Emit an event.
    emit Withdraw(block.timestamp, _msgSender(), _poolId, pool.item, _tokenIds);
  }

  /**
    Allow the owner to sweep either Ether or a particular ERC-20 token from the
    contract and send it to another address. This allows the owner of the shop
    to withdraw their funds after the sale is completed.

    @param _token The token to sweep the balance from; if a zero address is sent
      then the contract's balance of Ether will be swept.
    @param _amount The amount of token to sweep.
    @param _destination The address to send the swept tokens to.
  */
  function sweep (
    address _token,
    address _destination,
    uint256 _amount
  ) external onlyOwner {

    // A zero address means we should attempt to sweep Ether.
    if (_token == address(0)) {
      (bool success, ) = payable(_destination).call{ value: _amount }("");
      if (!success) { revert SweepingTransferFailed(); }

    // Otherwise, we should try to sweep an ERC-20 token.
    } else {
      IERC20(_token).safeTransfer(_destination, _amount);
    }
  }
}
