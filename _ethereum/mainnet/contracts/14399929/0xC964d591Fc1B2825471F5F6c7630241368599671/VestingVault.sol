// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IVestingVault.sol";

/**
 * @title VestingVault
 * @dev A token vesting contract that will release tokens gradually like a
 * standard equity vesting schedule, with a cliff and vesting period but no
 * arbitrary restrictions on the frequency of claims. Optionally has an initial
 * tranche claimable immediately after the cliff expires (in addition to any
 * amounts that would have vested up to that point but didn't due to a cliff).
 */
contract VestingVault is IVestingVault, Ownable {
  using SafeERC20 for IERC20;

  // The amount unclaimed for an address, whether or not vested.
  mapping(address => mapping (IERC20 => uint256)) public pendingAmount;

  // The allocations assigned to an address.
  mapping(address => Allocation[]) public userAllocations;

  /**
   * @dev Creates a new allocation for a beneficiary. Tokens are released
   * linearly over time until a given number of seconds have passed since the
   * start of the vesting schedule. Callable only by issuers.
   * @param _beneficiary The address to which tokens will be released
   * @param _amount The amount of the allocation (in wei)
   * @param _startAt The unix timestamp at which the vesting may begin
   * @param _cliff The number of seconds after _startAt before which no vesting occurs
   * @param _duration The number of seconds after which the entire allocation is vested
   */
  function issue(
    address _beneficiary,
    IERC20 _token,
    uint256 _amount,
    uint256 _startAt,
    uint256 _cliff,
    uint256 _duration
  ) external override {
    require(_amount > 0, "issue: zero-value allocations disallowed");
    require(_beneficiary != address(0), "issue: zero address disallowed");
    require(_cliff <= _duration, "issue: cliff exceeds duration");

    _token.safeTransferFrom(msg.sender, address(this), _amount);

    Allocation storage allocation = userAllocations[_beneficiary].push();
    allocation.token = _token;
    allocation.total = _amount;
    allocation.start = _startAt;
    allocation.duration = _duration;
    allocation.cliff = _cliff;

    pendingAmount[_beneficiary][_token] += _amount;

    emit Issued(
      _beneficiary,
      _token,
      _amount,
      _startAt,
      _cliff,
      _duration
    );
  }

  /**
   * @dev Revokes an existing allocation. Any unclaimed tokens are recalled
   * and sent to the caller. Callable only by the owner.
   * @param _beneficiary The address whose allocation is to be revoked
   * @param _id The allocation ID to revoke
   */
  function revoke(
    address _beneficiary,
    uint256 _id
  ) external override {
    Allocation storage allocation = userAllocations[_beneficiary][_id];

    // Calculate the remaining amount.
    uint256 total = allocation.total;
    uint256 remainder = total - allocation.claimed;

    // Update the total pending for the address.
    pendingAmount[_beneficiary][allocation.token] -= remainder;

    // Update the allocation to be claimed in full.
    allocation.claimed = total;

    // Transfer the tokens vested
    allocation.token.safeTransfer(owner(), remainder);
    emit Revoked(_beneficiary, _id, allocation.token, total, remainder);
  }

  /**
   * @dev Transfers vested tokens from any number of allocations to their beneficiary. Callable by anyone. May be gas-intensive.
   * @param _beneficiary The address that has vested tokens
   * @param _ids The vested allocation indexes
   */
  function release(
    address _beneficiary,
    uint256[] calldata _ids
  ) external override {
    for (uint256 i = 0; i < _ids.length; i++) {
      _release(_beneficiary, _ids[i]);
    }
  }

  /**
   * @dev Gets the number of allocations issued for a given address.
   * @param _beneficiary The address to check for allocations
   */
  function allocationCount(
    address _beneficiary
  ) external view override returns (uint256 count) {
    return userAllocations[_beneficiary].length;
  }

  /**
   * @dev Gets details about a given allocation.
   * @param _beneficiary Address to check
   * @param _id The allocation index
   * @return allocation The allocation
   * @return vested The total amount vested to date
   * @return releasable The amount currently releasable
   */
  function allocationSummary(
    address _beneficiary,
    uint256 _id
  ) external view override returns (
    Allocation memory allocation,
    uint256 vested,
    uint256 releasable
  ) {
    allocation = userAllocations[_beneficiary][_id];
    vested = _vestedAmount(allocation);
    releasable = _releasableAmount(allocation);
  }

  /**
   * @dev Transfers vested tokens from an allocation to its beneficiary.
   * @param _beneficiary The address that has vested tokens
   * @param _id The vested allocation index
   */
  function _release(
    address _beneficiary,
    uint256 _id
  ) internal {
    Allocation storage allocation = userAllocations[_beneficiary][_id];

    // Calculate the releasable amount.
    uint256 amount = _releasableAmount(allocation);
    require(amount > 0, "release: nothing here");

    // Add the amount to the allocation's total claimed.
    allocation.claimed += amount;

    // Subtract the amount from the beneficiary's total pending.
    pendingAmount[_beneficiary][allocation.token] -= amount;

    // Transfer the tokens to the beneficiary.
    allocation.token.safeTransfer(_beneficiary, amount);

    emit Released(
      _beneficiary,
      _id,
      allocation.token,
      amount,
      allocation.total - allocation.claimed
    );
  }

  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   * @param allocation Allocation to calculate against
   */
  function _releasableAmount(
    Allocation memory allocation
  ) internal view returns (uint256) {
    return _vestedAmount(allocation) - allocation.claimed;
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param allocation Allocation to calculate against
   */
  function _vestedAmount(
    Allocation memory allocation
  ) internal view returns (uint256 amount) {
    if (block.timestamp < allocation.start + allocation.cliff) {
      // Nothing is vested until after the start time + cliff length.
      amount = 0;
    } else if (
      block.timestamp >= allocation.start + allocation.duration
    ) {
      // The entire amount has vested if the entire duration has elapsed.
      amount = allocation.total;
    } else {
      // The initial tranche is available once the cliff expires, plus any portion of
      // tokens which have otherwise become vested as of the current block's timestamp.
      amount = allocation.total * (block.timestamp - allocation.start) / allocation.duration;
    }

    return amount;
  }
}
