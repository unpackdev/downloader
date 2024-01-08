// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

abstract contract BRegistry {
  /// @return listed is always 1 - Balancer guys said this return is not really used 
  function addPoolPair(address pool, address token1, address token2) external virtual returns(uint256 listed);
}