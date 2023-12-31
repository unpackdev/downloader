// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IStakeReceiver.sol";

contract TransferReceiver is IStakeReceiver {
  event StakeReceived(address sender, uint256 stakeId);
  error FailedToReceive(uint256 stakeId);
  uint256 internal _shouldErr;
  function setReceiveAction(uint256 shouldErr) external {
    _shouldErr = shouldErr;
  }
  function onStakeReceived(address from, uint256 stakeId) external {
    if (_shouldErr == 0) {
      emit StakeReceived(from, stakeId);
      return;
    }
    if (_shouldErr == 1) revert();
    if (_shouldErr == 2) revert("Failed to receive");
    if (_shouldErr == 3) revert FailedToReceive({
      stakeId: stakeId
    });
    if (_shouldErr == 4) {
      uint256[] memory list = new uint256[](3);
      emit StakeReceived(from, list[list.length]);
    }
  }
}
