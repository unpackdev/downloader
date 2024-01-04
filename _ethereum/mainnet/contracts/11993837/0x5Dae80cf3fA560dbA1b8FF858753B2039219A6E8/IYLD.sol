// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;


interface IYLD
{
  function renounceMinter() external;

  function mint(address account, uint256 amount) external returns (bool);
}
