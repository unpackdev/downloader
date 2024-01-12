// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IPool.sol";

interface ICorePool is IPool {
  function poolTokenReserve() external view returns (uint256);

  function stakeAsPool(address _staker, uint256 _amount) external;
}
