// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "./ExpandedERC20.sol";
import "./ERC20Snapshot.sol";

contract VotingToken is ExpandedERC20, ERC20Snapshot {
  constructor() public ExpandedERC20('UMA Voting Token v1', 'UMA', 18) {}

  function snapshot() external returns (uint256) {
    return _snapshot();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20, ERC20Snapshot) {
    super._beforeTokenTransfer(from, to, amount);
  }
}
