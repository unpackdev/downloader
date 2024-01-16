// SPDX-License-Identifier: ISC
pragma solidity 0.7.5;

import "./ILyra.sol";

interface IVestingEscrow {
  function initialize(
    address recipient,
    uint256 vestingAmount,
    uint256 vestingBegin,
    uint256 vestingCliff,
    uint256 vestingEnd
  ) external returns (bool);

  function transferOwnership(address newOwner) external;

  function token() external returns (ILyra);
}
