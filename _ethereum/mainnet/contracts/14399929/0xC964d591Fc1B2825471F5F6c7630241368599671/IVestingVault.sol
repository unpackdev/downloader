// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";

/**
 * @title VestingVault
 * @dev A token vesting contract that will release tokens gradually like a
 * standard equity vesting schedule, with a cliff and vesting period but no
 * arbitrary restrictions on the frequency of claims. Optionally has an initial
 * tranche claimable immediately after the cliff expires (in addition to any
 * amounts that would have vested up to that point but didn't due to a cliff).
 */
interface IVestingVault {
  event Issued(
    address indexed beneficiary,
    IERC20 token,
    uint256 amount,
    uint256 start,
    uint256 cliff,
    uint256 duration
  );

  event Released(
    address indexed beneficiary,
    uint256 indexed allocationId,
    IERC20 token,
    uint256 amount,
    uint256 remaining
  );

  event Revoked(
    address indexed beneficiary,
    uint256 indexed allocationId,
    IERC20 token,
    uint256 allocationAmount,
    uint256 revokedAmount
  );

  struct Allocation {
    IERC20 token;
    uint256 start;
    uint256 cliff;
    uint256 duration;
    uint256 total;
    uint256 claimed;
  }

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
  ) external;

  /**
   * @dev Revokes an existing allocation. Any unclaimed tokens are recalled
   * and sent to the caller. Callable only be issuers.
   * @param _beneficiary The address whose allocation is to be revoked
   * @param _id The allocation ID to revoke
   */
  function revoke(
    address _beneficiary,
    uint256 _id
  ) external;

  /**
   * @dev Transfers vested tokens from any number of allocations to their beneficiary. Callable by anyone. May be gas-intensive.
   * @param _beneficiary The address that has vested tokens
   * @param _ids The vested allocation indexes
   */
  function release(
    address _beneficiary, 
    uint256[] calldata _ids
  ) external;

  /**
   * @dev Gets the number of allocations issued for a given address.
   * @param _beneficiary The address to check for allocations
   */
  function allocationCount(
    address _beneficiary
  ) external view returns (
    uint256 count
  );

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
  ) external view returns (
    Allocation memory allocation,
    uint256 vested,
    uint256 releasable
  );
}
