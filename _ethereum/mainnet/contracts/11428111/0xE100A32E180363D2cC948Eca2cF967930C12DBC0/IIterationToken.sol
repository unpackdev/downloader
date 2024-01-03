// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;
interface IIterationToken {
  function lastRebalance (  ) external view returns ( uint256 );
  function minRebalanceAmount (  ) external view returns ( uint256 );
  function rebalanceLiquidity (  ) external;
  function rebalanceInterval (  ) external view returns ( uint256 );
}
