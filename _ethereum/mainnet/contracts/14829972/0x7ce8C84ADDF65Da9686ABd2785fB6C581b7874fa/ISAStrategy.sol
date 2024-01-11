// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

interface ISAStrategy {
  function invest(
    uint256 poolId,
    uint256 amount,
    bytes memory data
  ) external;

  function redeem(uint256 poolId, bytes memory data)
    external
    returns (bool pendingAdditionalWithdraw, uint256 amount);
}
