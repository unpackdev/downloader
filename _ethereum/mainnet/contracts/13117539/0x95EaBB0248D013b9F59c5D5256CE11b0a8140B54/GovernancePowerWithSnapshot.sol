// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./GovernancePowerDelegationERC20Mixin.sol";

/**
 * @title GovernancePowerWithSnapshot
 * @notice ERC20 including snapshots of balances on transfer-related actions
 * @author dYdX
 **/
abstract contract GovernancePowerWithSnapshot is GovernancePowerDelegationERC20Mixin {
  using SafeMath for uint256;

  /**
   * @dev The following storage layout points to the prior StakedToken.sol implementation:
   * _snapshots => _votingSnapshots
   * _snapshotsCounts =>  _votingSnapshotsCounts
   */
  mapping(address => mapping(uint256 => Snapshot)) public _votingSnapshots;
  mapping(address => uint256) public _votingSnapshotsCounts;
}
