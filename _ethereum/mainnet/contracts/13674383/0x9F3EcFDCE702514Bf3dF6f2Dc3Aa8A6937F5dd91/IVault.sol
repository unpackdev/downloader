// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
  // solhint-disable-previous-line no-empty-blocks
}

enum PoolSpecialization {
  GENERAL,
  MINIMAL_SWAP_INFO,
  TWO_TOKEN
}

enum WeightedPoolJoinKind {
  INIT,
  EXACT_TOKENS_IN_FOR_BPT_OUT,
  TOKEN_IN_FOR_EXACT_BPT_OUT,
  ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
}

enum WeightedPoolExitKind {
  EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
  EXACT_BPT_IN_FOR_TOKENS_OUT,
  BPT_IN_FOR_EXACT_TOKENS_OUT,
  MANAGEMENT_FEE_TOKENS_OUT
}

struct JoinPoolRequest {
  IAsset[] assets;
  uint256[] maxAmountsIn;
  bytes userData;
  bool fromInternalBalance;
}
struct ExitPoolRequest {
  IAsset[] assets;
  uint256[] minAmountsOut;
  bytes userData;
  bool toInternalBalance;
}

interface IVault {
  function setPaused(bool paused) external;

  function getPool(bytes32 poolId) external returns (address, PoolSpecialization);

  function joinPool(
    bytes32 poolId,
    address sender,
    address recipient,
    JoinPoolRequest memory request
  ) external payable;

  function exitPool(
    bytes32 poolId,
    address sender,
    address recipient,
    ExitPoolRequest memory request
  ) external payable;

  function getPoolTokens(bytes32 poolId)
    external
    returns (
      IERC20[] memory tokens,
      uint256[] memory balances,
      uint256 maxBlockNumber
    );
}
