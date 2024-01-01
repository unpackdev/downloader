// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDssPsm {
  function sellGem(address usr, uint256 gemAmt) external;
  function buyGem(address usr, uint256 gemAmt) external;
  function gemJoin() external view returns(address);
  function daiJoin() external view returns(address);
}
