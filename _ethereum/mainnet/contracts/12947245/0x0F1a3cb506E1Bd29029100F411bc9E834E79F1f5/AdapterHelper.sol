// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IAdapterRegistry.sol";
import "./ITokenAdapter.sol";
import "./IERC20.sol";
import "./LowGasSafeMath.sol";
import "./MinimalSignedMath.sol";
import "./ArrayHelper.sol";
import "./DynamicArrays.sol";
import "./Fraction.sol";
import "./SafeCast.sol";


library AdapterHelper {
  using Fraction for uint256;
  using LowGasSafeMath for uint256;
  using MinimalSignedMath for int256;
  using SafeCast for uint256;
  using SafeCast for int256;
  using ArrayHelper for address[];
  using ArrayHelper for uint256[];
  using DynamicArrays for uint256[];

  function packAdapterAndWeight(
    IErc20Adapter adapter,
    uint256 weight
  )
    internal
    pure
    returns (bytes32 encoded)
  {
    assembly {
      encoded := or(shl(96, adapter), weight)
    }
  }

  function packAdaptersAndWeights(
    IErc20Adapter[] memory adapters,
    uint256[] memory weights
  )
    internal
    pure
    returns (bytes32[] memory encodedArray)
  {
    uint256 len = adapters.length;
    encodedArray = new bytes32[](len);
    for (uint256 i; i < len; i++) {
      IErc20Adapter adapter = adapters[i];
      uint256 weight = weights[i];
      bytes32 encoded;
      assembly {
        encoded := or(shl(96, adapter), weight)
      }
      encodedArray[i] = encoded;
    }
  }

  function unpackAdapterAndWeight(bytes32 encoded)
    internal
    pure
    returns (
      IErc20Adapter adapter,
      uint256 weight
    )
  {
    assembly {
      adapter := shr(96, encoded)
      weight := and(
        encoded,
        0x0000000000000000000000000000000000000000ffffffffffffffffffffffff
      )
    }
  }

  function unpackAdaptersAndWeights(bytes32[] memory encodedArray)
    internal
    pure
    returns (
      IErc20Adapter[] memory adapters,
      uint256[] memory weights
    )
  {
    uint256 len = encodedArray.length;
    adapters = new IErc20Adapter[](len);
    weights = new uint256[](len);
    for (uint256 i; i < len; i++) {
      bytes32 encoded = encodedArray[i];
      IErc20Adapter adapter;
      uint256 weight;
      assembly {
        adapter := shr(96, encoded)
        weight := and(
          encoded,
          0x0000000000000000000000000000000000000000ffffffffffffffffffffffff
        )
      }
      adapters[i] = adapter;
      weights[i] = weight;
    }
  }

  function getNetAPR(
    IErc20Adapter[] memory adapters,
    uint256[] memory weights,
    int256[] memory liquidityDeltas
  ) internal view returns (uint256 netAPR) {
    uint256 len = adapters.length;
    for (uint256 i; i < len; i++) {
      uint256 weight = weights[i];
      if (weight > 0) {
        netAPR = netAPR.add(
          adapters[i].getHypotheticalAPR(liquidityDeltas[i]).mulFractionE18(weight)
        );
      }
    }
  }

  function getLiquidityDeltas(
    uint256 totalProductiveBalance,
    uint256[] memory balances,
    uint256[] memory weights
  ) internal pure returns (int256[] memory deltas) {
    uint256 len = balances.length;
    deltas = new int256[](len);
    for (uint256 i; i < len; i++) {
      uint256 targetBalance = totalProductiveBalance.mulFractionE18(weights[i]);
      deltas[i] = targetBalance.toInt256().sub(balances[i].toInt256());
    }
  }

  function getBalances(IErc20Adapter[] memory adapters) internal view returns (uint256[] memory balances) {
    uint256 len = adapters.length;
    balances = new uint256[](len);
    for (uint256 i; i < len; i++) balances[i] = adapters[i].balanceUnderlying();
  }

  function getExcludedAdapterIndices(
    IErc20Adapter[] memory oldAdapters,
    IErc20Adapter[] memory newAdapters
  ) internal pure returns (uint256[] memory excludedAdapterIndices) {
    uint256 selfLen = oldAdapters.length;
    uint256 otherLen = newAdapters.length;
    excludedAdapterIndices = DynamicArrays.dynamicUint256Array(selfLen);
    for (uint256 i; i < selfLen; i++) {
      IErc20Adapter element = oldAdapters[i];
      for (uint256 j; j < otherLen; j++) {
        if (element == newAdapters[j]) {
          element = IErc20Adapter(0);
          break;
        }
      }
      if (element != IErc20Adapter(0)) {
        excludedAdapterIndices.dynamicPush(i);
      }
    }
  }

  /**
   * @dev Rebalances the vault by withdrawing tokens from adapters with negative liquidity deltas
   * and depositing to adapters with positive liquidity deltas.
   *
   * Note: This does not necessarily result in a vault composition that matches the assigned weights,
   * as some of the lending markets for adapters with negative deltas may have insufficient liquidity
   * to process withdrawals of the desired amounts. In this case, the vault will withdraw what it can
   * and deposit up to the amount withdrawn to the other markets.
   *
   * Returns an array with indices of the adapters that both have a weight of zero and were able to
   * process a withdrawal of the vault's full balance. This array is used to remove those adapters.
   */
  function rebalance(
    IErc20Adapter[] memory adapters,
    uint256[] memory weights,
    int256[] memory liquidityDeltas,
    uint256 reserveBalance
  ) internal returns (uint256[] memory removedIndices) {
    uint256 len = liquidityDeltas.length;
    removedIndices = DynamicArrays.dynamicUint256Array(len);
    uint256 totalAvailableBalance = reserveBalance;
    // Execute withdrawals first
    for (uint256 i; i < len; i++) {
      int256 delta = liquidityDeltas[i];
      if (delta < 0) {
        uint256 amountToWithdraw = (-delta).toUint256();
        uint256 amountWithdrawn = adapters[i].withdrawUnderlyingUpTo(amountToWithdraw);
        // If the weight is 0, `amountToWithdraw` is the balance of the vault in the adapter
        // and the vault intends to remove the adapter. If the rebalance is able to withdraw
        // the full balance, it will mark the index of the adapter as able to be removed
        // so that it can be deleted by the rebalance function.
        if (weights[i] == 0 && amountWithdrawn == amountToWithdraw) {
          removedIndices.dynamicPush(i);
        }
        totalAvailableBalance = totalAvailableBalance.add(amountWithdrawn);
      }
    }
    // Execute deposits after
    for (uint256 i; i < len; i++) {
      int256 delta = liquidityDeltas[i];
      if (delta > 0) {
        if (totalAvailableBalance == 0) break;
        uint256 amountToDeposit = delta.toUint256();
        if (amountToDeposit >= totalAvailableBalance) {
          IErc20Adapter(adapters[i]).deposit(totalAvailableBalance);
          break;
        }
        IErc20Adapter(adapters[i]).deposit(amountToDeposit);
        totalAvailableBalance = totalAvailableBalance.sub(amountToDeposit);
      }
    }
  }
}