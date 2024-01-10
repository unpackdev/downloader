// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface IRoality {
  function roalityAccount() external view returns (address);
  function roality() external view returns (uint256);
  function setRoalityAccount(address account) external;
  function setRoality(uint256 thousandths) external;
}