// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./AbstractPool.sol";
import "./BPool.sol";
import "./BFactory.sol";

abstract contract ConfigurableRightsPool is AbstractPool {
  struct PoolParams {
    string poolTokenSymbol;
    string poolTokenName;
    address[] constituentTokens;
    uint[] tokenBalances;
    uint[] tokenWeights;
    uint swapFee;
  }

  struct CrpParams {
    uint initialSupply;
    uint minimumWeightChangeBlockPeriod;
    uint addTokenTimeLockInBlocks;
  }

  struct GradualUpdateParams {
    uint startBlock;
    uint endBlock;
    uint[] startWeights;
    uint[] endWeights;
  }

  struct Rights {
        bool canPauseSwapping;
        bool canChangeSwapFee;
        bool canChangeWeights;
        bool canAddRemoveTokens;
        bool canWhitelistLPs;
        bool canChangeCap;
  }

  struct NewTokenParams {
        address addr;
        bool isCommitted;
        uint commitBlock;
        uint denorm;
        uint balance;
  }

  function createPool(uint initialSupply, uint minimumWeightChangeBlockPeriod, uint addTokenTimeLockInBlocks) external virtual;
  function createPool(uint initialSupply) external virtual;
  function updateWeightsGradually(uint[] calldata newWeights, uint startBlock, uint endBlock) external virtual;
  function removeToken(address token) external virtual;
  function bPool() external view virtual returns (BPool);
  function bFactory() external view virtual returns(BFactory);
  function minimumWeightChangeBlockPeriod() external view virtual returns(uint);
  function addTokenTimeLockInBlocks() external view virtual returns(uint);
  function bspCap() external view virtual returns(uint);
  function pokeWeights() external virtual;
  function gradualUpdate() external view virtual returns(GradualUpdateParams memory);
  function setCap(uint newCap) external virtual;
  function updateWeight(address token, uint newWeight) external virtual;
  function commitAddToken(address token, uint balance, uint denormalizedWeight) external virtual;
  function applyAddToken() external virtual;
  function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external virtual;
  function joinswapExternAmountIn(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut) external virtual;
  function joinswapPoolAmountOut(address tokenIn, uint poolAmountOut, uint maxAmountIn) external virtual;
  function exitswapPoolAmountIn(address tokenOut, uint poolAmountIn, uint minAmountOut) external virtual;
  function exitswapExternAmountOut(address tokenOut, uint tokenAmountOut, uint maxPoolAmountIn) external virtual;
  function whitelistLiquidityProvider(address provider) external virtual;
  function removeWhitelistedLiquidityProvider(address provider) external virtual;
  function mintPoolShareFromLib(uint amount) public virtual;
  function pushPoolShareFromLib(address to, uint amount) public virtual;
  function pullPoolShareFromLib(address from, uint amount) public virtual;
  function burnPoolShareFromLib(uint amount) public virtual;
  function rights() external view virtual returns(Rights memory);
  function newToken() external view virtual returns(NewTokenParams memory);
}