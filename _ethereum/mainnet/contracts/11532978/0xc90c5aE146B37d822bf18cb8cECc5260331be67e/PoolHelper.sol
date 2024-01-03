// SPDX-License-Identifier: UNLICENSED;
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeMath.sol";

import "./YGYStorageV1.sol";

library PoolHelper {
  using SafeMath for uint256;

  function getPool(uint256 _poolId, YGYStorageV1 _storage) internal view returns (YGYStorageV1.PoolInfo memory) {
    (
      IERC20 token,
      uint256 allocPoint,
      uint256 accRAMPerShare,
      uint256 accYGYPerShare,
      bool withdrawable,
      uint256 effectiveAdditionalTokensFromBoosts
    ) = _storage.poolInfo(_poolId);
    return
      YGYStorageV1.PoolInfo({
        token: token,
        allocPoint: allocPoint,
        accRAMPerShare: accRAMPerShare,
        accYGYPerShare: accYGYPerShare,
        withdrawable: withdrawable,
        effectiveAdditionalTokensFromBoosts: effectiveAdditionalTokensFromBoosts
      });
  }
}
