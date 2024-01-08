// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ISwap.sol";
import "./ISynapseBridge.sol";

contract NerveBridgeZap {
  using SafeERC20 for IERC20;

  ISwap baseSwap;
  ISynapseBridge synapseBridge;
  IERC20[] public baseTokens;
  uint256 constant MAX_UINT256 = 2**256 - 1;

  constructor(ISwap _baseSwap, ISynapseBridge _synapseBridge) public {
    baseSwap = _baseSwap;
    synapseBridge = _synapseBridge;
    {
      uint8 i;
      for (; i < 32; i++) {
        try _baseSwap.getToken(i) returns (IERC20 token) {
          baseTokens.push(token);
          token.safeApprove(address(_baseSwap), MAX_UINT256);
        } catch {
          break;
        }
      }
      require(i > 1, 'baseSwap must have at least 2 tokens');
    }
  }

  function zapAndDeposit(
    address to,
    uint256 chainId,
    IERC20 token,
    uint256[] calldata liquidityAmounts,
    uint256 minToMint,
    uint256 deadline
  ) public {
    // add liquidity

    uint256 liqAdded = baseSwap.addLiquidity(
      liquidityAmounts,
      minToMint,
      deadline
    );
    // deposit into bridge, gets nUSD
    token.safeApprove(address(synapseBridge), liqAdded);
    synapseBridge.deposit(to, chainId, token, liqAdded);
  }

  function zapAndDepositAndSwap(
    address to,
    uint256 chainId,
    IERC20 token,
    uint256[] calldata liquidityAmounts,
    uint256 minToMint,
    uint256 liqDeadline,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 minDy,
    uint256 swapDeadline
  ) public {
    uint256 liqAdded = baseSwap.addLiquidity(
      liquidityAmounts,
      minToMint,
      liqDeadline
    );
    // deposit into bridge, bridge attemps to swap into desired asset
    token.safeApprove(address(synapseBridge), liqAdded);
    synapseBridge.depositAndSwap(
      to,
      chainId,
      token,
      liqAdded,
      tokenIndexFrom,
      tokenIndexTo,
      minDy,
      swapDeadline
    );
  }
}
