// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

interface IFeeController {
  function isPaused() external view returns (bool);

  function isFeeless(address) external view returns (bool);

  function isBlocked(address) external view returns (bool);

  function setFee(uint256) external;

  function editNoFeeList(address, bool) external;

  function editBlockList(address, bool) external;

  function applyFee(
    address,
    address,
    uint256
  ) external view returns (uint256, uint256);
}
