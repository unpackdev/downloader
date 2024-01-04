// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

library AutoRewardTokenStorage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'solidstate.contracts.storage.AutoRewardToken'
  );

  struct Layout {
    uint fee;
    uint cumulativeRewardPerToken;
    mapping (address => uint) rewardsExcluded;
    mapping (address => uint) rewardsReserved;
  }

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }
}
