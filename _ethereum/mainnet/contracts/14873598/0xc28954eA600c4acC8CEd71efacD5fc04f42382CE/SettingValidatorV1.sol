// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.14;

interface SettingValidatorV1 {
  function isValidUnlockedSetting(bytes32[] calldata path, uint64 releaseTime, bytes calldata value) external view returns (bool);
}