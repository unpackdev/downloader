// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWsSQUID {
  function approve(address spender, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function wrapFromsSQUID( uint _amount ) external returns ( uint );
  function unwrapTosSQUID( uint _amount ) external returns ( uint );
}
