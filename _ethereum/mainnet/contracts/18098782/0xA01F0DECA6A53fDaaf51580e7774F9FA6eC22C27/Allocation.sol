// Allocation (ALLO)
//
// https://alloeth.com
// https://t.me/allocationofficial
//
// Creating a new standard for the way KOLs, influencers, or any outside party
// receiving off market token allocations receive allos in the future.
//
// AlloVester.sol allows ANYONE to create linearly vested token allocations for anyone else!
// This contract contains built-in ENS integration to create token allocations
// for wallets tied to a human-readable name and built-in linear vesting where anyone who
// receives an allocation will vest over a specified time frame. Linear vesting protects
// the project and community while incentivizing those with allocations to help push
// the project and narrative as much as possible over time.
//
// $ALLO information:
//   - 0/0 tax
//   - 80% supply goes to LP, 20% will be used for ALLO allocations
//   - All ALLO allocations will linear vest over a 4 month time frame
//   - All allocations integrate with ENS providing full transparency
//   - Ability to create ANY token allocation on any vesting schedule desired
//   - Revenue share to ALLO holders for any custom allocation which burns ALLO or pays fee in native token
//   - ALLO community decides the right KOLs we add allos for to push the narrative

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC20.sol";
import "./AlloVester.sol";

contract Allocation is ERC20 {
  AlloVester public immutable ALLO_VESTER;
  uint256 public constant ALLO_TIME_SPAN = 120 days; // 4 months

  constructor(
    address _nameService,
    address _vesterOwner
  ) ERC20('Allocation', 'ALLO') {
    ALLO_VESTER = new AlloVester(_nameService);
    ALLO_VESTER.transferOwnership(_vesterOwner);
    _mint(_msgSender(), 100_000_000 * 10 ** 18);
  }

  function claimAllocation(string memory _ensName) external {
    ALLO_VESTER.vestedAlloClaim(address(this), _ensName);
  }

  function createAllocation(string memory _ensName, uint256 _amount) external {
    uint256 _total = ALLO_VESTER.createCostALLO() + _amount;
    _transfer(_msgSender(), address(this), _total);
    _approve(address(this), address(ALLO_VESTER), _total);
    ALLO_VESTER.vestedAlloCreate(
      address(this),
      _ensName,
      _amount,
      block.timestamp,
      block.timestamp + ALLO_TIME_SPAN,
      false
    );
  }
}
