// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./Ownable.sol";
import "./RebalanceValidation.sol";
import "./SafeCast.sol";
import "./NirnVaultBase.sol";


contract NirnVault is NirnVaultBase {
  using Fraction for uint256;
  using TransferHelper for address;
  using LowGasSafeMath for uint256;
  using MinimalSignedMath for int256;
  using SafeCast for uint256;
  using SafeCast for int256;
  using ArrayHelper for uint256[];
  using ArrayHelper for bytes32[];
  using ArrayHelper for IErc20Adapter[];
  using DynamicArrays for uint256[];
  using AdapterHelper for IErc20Adapter[];

/* ========== Constructor ========== */

  constructor(
    address _registry,
    address _eoaSafeCaller
  ) NirnVaultBase(_registry, _eoaSafeCaller) {}

/* ========== Status Queries ========== */

  function getCurrentLiquidityDeltas() external view override returns (int256[] memory liquidityDeltas) {
    (IErc20Adapter[] memory adapters, uint256[] memory weights) = getAdaptersAndWeights();
    BalanceSheet memory balanceSheet = getBalanceSheet(adapters);
    liquidityDeltas = AdapterHelper.getLiquidityDeltas(
      balanceSheet.totalProductiveBalance,
      balanceSheet.balances,
      weights
    );
  }

  function getAPR() external view override returns (uint256) {
    (DistributionParameters memory params,,) = currentDistribution();
    return params.netAPR;
  }

/* ========== Deposit/Withdraw ========== */

  function deposit(uint256 amount) external override returns (uint256 shares) {
    shares = depositTo(amount, msg.sender);
  }

  function depositTo(uint256 amount, address to) public override returns (uint256 shares) {
    uint256 bal = balance();
    uint256 max = maximumUnderlying;
    if (max > 0) {
      require(bal.add(amount) <= max, "maximumUnderlying");
    }
    underlying.safeTransferFrom(msg.sender, address(this), amount);
    uint256 supply = claimFees(bal, totalSupply);
    shares = supply == 0 ? amount : amount.mul(supply) / bal;
    _mint(to, shares);
    emit Deposit(shares, amount);
  }

  function withdraw(uint256 shares) external override returns (uint256 amountOut) {
    (IErc20Adapter[] memory adapters, uint256[] memory weights) = getAdaptersAndWeights();
    BalanceSheet memory balanceSheet = getBalanceSheet(adapters);
    uint256 supply = claimFees(balanceSheet.totalBalance, totalSupply);
    amountOut = shares.mul(balanceSheet.totalBalance) / supply;
    withdrawInternal(
      shares,
      amountOut,
      adapters,
      weights,
      balanceSheet
    );
  }

  function withdrawUnderlying(uint256 amount) external override returns (uint256 shares) {
    (IErc20Adapter[] memory adapters, uint256[] memory weights) = getAdaptersAndWeights();
    BalanceSheet memory balanceSheet = getBalanceSheet(adapters);
    uint256 supply = claimFees(balanceSheet.totalBalance, totalSupply);
    shares = amount.mul(supply) / balanceSheet.totalBalance;
    withdrawInternal(
      shares,
      amount,
      adapters,
      weights,
      balanceSheet
    );
  }

  function withdrawInternal(
    uint256 shares,
    uint256 amountOut,
    IErc20Adapter[] memory adapters,
    uint256[] memory weights,
    BalanceSheet memory balanceSheet
  ) internal {
    _burn(msg.sender, shares);
    emit Withdrawal(shares, amountOut);
    uint256 newReserves = balanceSheet.totalBalance.sub(amountOut).mulFractionE18(reserveRatio);
    withdrawToMatchAmount(
      adapters,
      weights,
      balanceSheet.balances,
      balanceSheet.reserveBalance,
      amountOut,
      newReserves
    );
    _transferOut(msg.sender, amountOut);
  }

  function withdrawToMatchAmount(
    IErc20Adapter[] memory adapters,
    uint256[] memory weights,
    uint256[] memory balances,
    uint256 _reserveBalance,
    uint256 amount,
    uint256 newReserves
  ) internal {
    if (amount > _reserveBalance) {
      uint256 remainder = amount.sub(_reserveBalance);
      uint256 len = balances.length;
      uint256[] memory removeIndices = DynamicArrays.dynamicUint256Array(len);
      for (uint256 i; i < len; i++) {
        uint256 bal = balances[i];
        if (bal == 0) continue;
        // If the balance is sufficient to withdraw both the remainder and the new reserves,
        // withdraw the remainder and the new reserves. Otherwise, withdraw the balance.
        uint256 optimalWithdrawal = remainder.add(newReserves);
        uint256 amountToWithdraw = bal > optimalWithdrawal
          ? optimalWithdrawal
          : bal;
        uint256 amountWithdrawn = adapters[i].withdrawUnderlyingUpTo(amountToWithdraw);
        remainder = remainder >= amountWithdrawn ? remainder - amountWithdrawn : 0;
        if (weights[i] == 0 && amountWithdrawn == bal) {
          removeIndices.dynamicPush(i);
        }
        if (remainder == 0) break;
      }
      require(remainder == 0, "insufficient available balance");
      removeAdapters(removeIndices);
    }
  }

/* ========== Rebalance Actions ========== */

  function rebalance() external override onlyEOA {
    (IErc20Adapter[] memory adapters, uint256[] memory weights) = getAdaptersAndWeights();
    BalanceSheet memory balanceSheet = getBalanceSheet(adapters);
    int256[] memory liquidityDeltas = AdapterHelper.getLiquidityDeltas(balanceSheet.totalProductiveBalance, balanceSheet.balances, weights);
    uint256[] memory removedIndices = AdapterHelper.rebalance(
      adapters,
      weights,
      liquidityDeltas,
      balanceSheet.reserveBalance
    );
    removeAdapters(removedIndices);
    emit Rebalanced();
  }

  function rebalanceWithNewWeights(uint256[] memory proposedWeights) external override onlyEOA changesComposition {
    (
      DistributionParameters memory params,
      uint256 totalProductiveBalance,
      uint256 _reserveBalance
    ) = currentDistribution();
    RebalanceValidation.validateProposedWeights(params.weights, proposedWeights);
    // Get liquidity deltas and APR for new weights
    int256[] memory proposedLiquidityDeltas = AdapterHelper.getLiquidityDeltas(totalProductiveBalance, params.balances, proposedWeights);
    uint256 proposedAPR = AdapterHelper.getNetAPR(params.adapters, proposedWeights, proposedLiquidityDeltas).mulSubFractionE18(reserveRatio);
    // Validate rebalance results in sufficient APR improvement
    RebalanceValidation.validateSufficientImprovement(params.netAPR, proposedAPR, minimumAPRImprovement);
    // Rebalance and remove adapters with 0 weight which the vault could fully exit.
    uint256[] memory removedIndices = AdapterHelper.rebalance(params.adapters, proposedWeights, proposedLiquidityDeltas, _reserveBalance);
    uint256 removeLen = removedIndices.length;
    if (removeLen > 0) {
      for (uint256 i = removeLen; i > 0; i--) {
        uint256 rI = removedIndices[i-1];
        emit AdapterRemoved(params.adapters[rI]);
        params.adapters.mremove(rI);
        proposedWeights.mremove(rI);
      }
    }
    setAdaptersAndWeights(params.adapters, proposedWeights);
  }

  function currentDistribution() public view override returns (
    DistributionParameters memory params,
    uint256 totalProductiveBalance,
    uint256 _reserveBalance
  ) {
    uint256 _reserveRatio = reserveRatio;
    (params.adapters, params.weights) = getAdaptersAndWeights();
    uint256 len = params.adapters.length;
    uint256 netAPR;
    params.balances = params.adapters.getBalances();
    _reserveBalance = reserveBalance();
    totalProductiveBalance = params.balances.sum().add(_reserveBalance).mulSubFractionE18(_reserveRatio);
    params.liquidityDeltas = new int256[](len);
    for (uint256 i; i < len; i++) {
      IErc20Adapter adapter = params.adapters[i];
      uint256 weight = params.weights[i];
      uint256 targetBalance = totalProductiveBalance.mulFractionE18(weight);
      int256 liquidityDelta = targetBalance.toInt256().sub(params.balances[i].toInt256());
      netAPR = netAPR.add(
        adapter.getHypotheticalAPR(liquidityDelta).mulFractionE18(weight)
      );
      params.liquidityDeltas[i] = liquidityDelta;
    }
    params.netAPR = netAPR.mulSubFractionE18(_reserveRatio);
  }

  function processProposedDistribution(
    DistributionParameters memory currentParams,
    uint256 totalProductiveBalance,
    IErc20Adapter[] calldata proposedAdapters,
    uint256[] calldata proposedWeights
  ) internal view returns (DistributionParameters memory params) {
    uint256[] memory excludedAdapterIndices = currentParams.adapters.getExcludedAdapterIndices(proposedAdapters);
    uint256 proposedSize = proposedAdapters.length;
    uint256 expandedSize = proposedAdapters.length + excludedAdapterIndices.length;
    params.adapters = new IErc20Adapter[](expandedSize);
    params.weights = new uint256[](expandedSize);
    params.balances = new uint256[](expandedSize);
    params.liquidityDeltas = new int256[](expandedSize);
    uint256 i;
    uint256 netAPR;
    for (; i < proposedSize; i++) {
      IErc20Adapter adapter = proposedAdapters[i];
      params.adapters[i] = adapter;
      uint256 weight = proposedWeights[i];
      params.weights[i] = weight;
      uint256 targetBalance = totalProductiveBalance.mulFractionE18(weight);
      uint256 _balance = adapter.balanceUnderlying();
      params.balances[i] = _balance;
      int256 liquidityDelta = targetBalance.toInt256().sub(_balance.toInt256());
      netAPR = netAPR.add(
        adapter.getHypotheticalAPR(liquidityDelta).mulFractionE18(weight)
      );
      params.liquidityDeltas[i] = liquidityDelta;
    }
    netAPR = netAPR.mulSubFractionE18(reserveRatio);
    RebalanceValidation.validateSufficientImprovement(currentParams.netAPR, netAPR, minimumAPRImprovement);
    for (; i < expandedSize; i++) {
      // i - proposedSize = index in excluded adapter indices array
      // The value in excludedAdapterIndices is the index in the current adapters array
      // for the adapter which is being removed.
      // The lending markets for these adapters may or may not have sufficient liquidity to
      // process a full withdrawal requested by the vault, so we keep those adapters in the
      // adapters list, but set a weight of 0 and a liquidity delta of -balance
      uint256 rI = excludedAdapterIndices[i - proposedSize];
      params.adapters[i] = currentParams.adapters[rI];
      params.weights[i] = 0;
      uint256 _balance = currentParams.balances[rI];
      params.balances[i] = _balance;
      params.liquidityDeltas[i] = -_balance.toInt256();
    }
  }

  function rebalanceWithNewAdapters(
    IErc20Adapter[] calldata proposedAdapters,
    uint256[] calldata proposedWeights
  ) external override onlyEOA changesComposition {
    RebalanceValidation.validateAdaptersAndWeights(registry, underlying, proposedAdapters, proposedWeights);
    (
      DistributionParameters memory currentParams,
      uint256 totalProductiveBalance,
      uint256 _reserveBalance
    ) = currentDistribution();
    DistributionParameters memory proposedParams = processProposedDistribution(
      currentParams,
      totalProductiveBalance,
      proposedAdapters,
      proposedWeights
    );
    beforeAddAdapters(proposedParams.adapters);
    uint256[] memory removedIndices = AdapterHelper.rebalance(
      proposedParams.adapters,
      proposedParams.weights,
      proposedParams.liquidityDeltas,
      _reserveBalance
    );
    uint256 removedLen = removedIndices.length;
    if (removedLen > 0) {
      // The indices to remove are necessarily in ascending order, so as long as we remove
      // them in reverse, the removal of elements will not break the other indices.
      for (uint256 i = removedLen; i > 0; i--) {
        uint256 rI = removedIndices[i-1];
        emit AdapterRemoved(proposedParams.adapters[rI]);
        proposedParams.adapters.mremove(rI);
        proposedParams.weights.mremove(rI);
      }
    }
    setAdaptersAndWeights(proposedParams.adapters, proposedParams.weights);
  }

  function _transferOut(address to, uint256 amount) internal {
    underlying.safeTransfer(to, amount);
  }
}