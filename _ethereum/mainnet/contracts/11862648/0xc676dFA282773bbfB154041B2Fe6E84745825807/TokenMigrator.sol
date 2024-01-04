// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "./FixedPoint.sol";
import "./ExpandedIERC20.sol";
import "./VotingToken.sol";

contract TokenMigrator {
  using FixedPoint for FixedPoint.Unsigned;

  VotingToken public oldToken;
  ExpandedIERC20 public newToken;

  uint256 public snapshotId;
  FixedPoint.Unsigned public rate;

  mapping(address => bool) public hasMigrated;

  constructor(
    FixedPoint.Unsigned memory _rate,
    address _oldToken,
    address _newToken
  ) public {
    require(_rate.isGreaterThan(0), "Rate can't be 0");
    rate = _rate;
    newToken = ExpandedIERC20(_newToken);
    oldToken = VotingToken(_oldToken);
    snapshotId = oldToken.snapshot();
  }

  function migrateTokens(address tokenHolder) external {
    require(!hasMigrated[tokenHolder], 'Already migrated tokens');
    hasMigrated[tokenHolder] = true;

    FixedPoint.Unsigned memory oldBalance =
      FixedPoint.Unsigned(oldToken.balanceOfAt(tokenHolder, snapshotId));

    if (!oldBalance.isGreaterThan(0)) {
      return;
    }

    FixedPoint.Unsigned memory newBalance = oldBalance.div(rate);
    require(newToken.mint(tokenHolder, newBalance.rawValue), 'Mint failed');
  }
}
