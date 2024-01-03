// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;
interface IBalancer {
  function treasury (  ) external view returns ( address payable );
  function setTreasury ( address treasuryN ) external;
  function rebalance ( address rewardRecp ) external returns ( uint256 );
  function AddLiq (  ) external returns (bool);
}