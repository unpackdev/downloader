// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

library AllowListClaimStorage {
  struct Layout {
    // storage for the merkle tree root
    bytes32 merkleRoot;
    // how many tokens are already claimed by a given account
    mapping(address => uint256) alreadyClaimed;
    // start of the claiming period
    uint256 claimPeriodStart;
    // end of the claiming period
    uint256 claimPeriodEnd;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256('citydao.contracts.storage.AllowList');

  //noinspection NoReturn
  function layout() internal pure returns (Layout storage _layout) {
    bytes32 slot = STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      _layout.slot := slot
    }
  }

  function merkleRoot() internal view returns (bytes32) {
    return layout().merkleRoot;
  }

  function setMerkleRoot(bytes32 _merkleRoot) internal {
    layout().merkleRoot = _merkleRoot;
  }

  function alreadyClaimed(address account) internal view returns (uint256) {
    return layout().alreadyClaimed[account];
  }

  function setAlreadyClaimed(address account, uint256 amount) internal {
    layout().alreadyClaimed[account] = amount;
  }

  function claimPeriod() internal view returns (uint256, uint256) {
    Layout storage data = layout();
    return (data.claimPeriodStart, data.claimPeriodEnd);
  }

  function claimPeriodStart() internal view returns (uint256) {
    return layout().claimPeriodStart;
  }

  function claimPeriodEnd() internal view returns (uint256) {
    return layout().claimPeriodEnd;
  }

  function setClaimPeriod(uint256 _start, uint256 _end) internal {
    Layout storage data = layout();
    data.claimPeriodStart = _start;
    data.claimPeriodEnd = _end;
  }
}
