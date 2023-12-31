// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

import "./SafeERC20.sol";

import "./IBalancerVault.sol";
import "./IStablePool.sol";
import "./WeightedMath.sol";
import "./BeefyBalancerStructs.sol";
import "./StableMath.sol";
import "./console.sol";

library BalancerLibPub {
  function balancerJoin(address _vault, bytes32 _poolId, address _tokenIn, uint256 _amountIn) external {
    BalancerLib.balancerJoin(_vault, _poolId, _tokenIn, _amountIn);
  }

  function balancerJoinMany(address _vault, bytes32 _poolId, uint256[] memory _amountsIn) external {
    BalancerLib.balancerJoinMany(_vault, _poolId, _amountsIn);
  }

  function balancerSwap(
      BalancerLib.SwapParams memory params,
      IBalancerVault.FundManagement memory funds,
      IBalancerVault.SwapKind swapKind
  ) external returns (uint256) {
    return BalancerLib.balancerSwap(params, funds, swapKind);
  }

  function balancerBatchSwap(address _vault, IBalancerVault.SwapKind _swapKind, address[] memory _route, bytes32[] memory pools, IBalancerVault.FundManagement memory _funds, uint256 _amountIn) internal returns (int256[] memory) {
    return BalancerLib.balancerBatchSwap(_vault, _swapKind, _route, pools, _funds, _amountIn);
  }

  function balancerBatchQuote(address _vault, IBalancerVault.SwapKind _swapKind, address[] memory _route, bytes32[] memory pools, IBalancerVault.FundManagement memory _funds, uint256 _amountIn) internal returns (int256[] memory) {
    return BalancerLib.balancerBatchQuote(_vault, _swapKind, _route, pools, _funds, _amountIn);
  }
}

library BalancerLib {
    using SafeERC20 for IERC20;

    struct SwapParams {
        address vault;
        bytes32 poolId; 
        address tokenIn; 
        address tokenOut; 
        uint256 amountIn;
	  }

    /******************************************************
     *                                                    *
     *                  ACTIONS FUNCTIONS                 *
     *                                                    *
     ******************************************************/

    function balancerJoin(address _vault, bytes32 _poolId, address _tokenIn, uint256 _amountIn) internal {
        (address[] memory lpTokens,,) = IBalancerVault(_vault).getPoolTokens(_poolId);
        uint256[] memory amounts = new uint256[](lpTokens.length);
        for (uint256 i = 0; i < amounts.length;) {
            amounts[i] = lpTokens[i] == _tokenIn ? _amountIn : 0;
            unchecked { ++i; }
        }
        bytes memory userData = abi.encode(1, amounts, 1);

        IBalancerVault.JoinPoolRequest memory request = IBalancerVault.JoinPoolRequest(lpTokens, amounts, userData, false);
        IBalancerVault(_vault).joinPool(_poolId, address(this), address(this), request);
    }

    function balancerExit(address _vault, bytes32 _poolId, address _tokenOut, uint256 bptAmountIn, uint256 _minAmountOut) internal {
        (address[] memory lpTokens,,) = IBalancerVault(_vault).getPoolTokens(_poolId);
        uint256[] memory amounts = new uint256[](lpTokens.length);
        for (uint256 i = 0; i < amounts.length;) {
            amounts[i] = lpTokens[i] == _tokenOut ? _minAmountOut : 0;
            unchecked { ++i; }
        }

        bytes memory userData = abi.encode(0, bptAmountIn, 0);

        IBalancerVault.ExitPoolRequest memory request = IBalancerVault.ExitPoolRequest(lpTokens, amounts, userData, false);
        IBalancerVault(_vault).exitPool(_poolId, address(this), payable(address(this)), request);
    }
    
    function balancerJoinMany(address _vault, bytes32 _poolId, uint256[] memory _amountsIn) internal {
        (address[] memory lpTokens,,) = IBalancerVault(_vault).getPoolTokens(_poolId);
   
        bytes memory userData = abi.encode(1, _amountsIn, 1);

        IBalancerVault.JoinPoolRequest memory request = IBalancerVault.JoinPoolRequest(lpTokens, _amountsIn, userData, false);
        IBalancerVault(_vault).joinPool(_poolId, address(this), address(this), request);
    }

    function balancerExitMany(address _vault, bytes32 _poolId, uint256 bptAmountIn, uint256[] memory _minAmountsOut) internal {
        (address[] memory lpTokens,,) = IBalancerVault(_vault).getPoolTokens(_poolId);

        bytes memory userData = abi.encode(1, bptAmountIn);

        IBalancerVault.ExitPoolRequest memory request = IBalancerVault.ExitPoolRequest(lpTokens, _minAmountsOut, userData, false);
        IBalancerVault(_vault).exitPool(_poolId, address(this), payable(address(this)), request);
    }


    // Swap funds on Balancer
    function balancerSwap(
        SwapParams memory params,
        IBalancerVault.FundManagement memory funds,
        IBalancerVault.SwapKind swapKind
    ) internal returns (uint256) {
      IBalancerVault.SingleSwap memory singleSwap = IBalancerVault.SingleSwap(params.poolId, swapKind, params.tokenIn, params.tokenOut, params.amountIn, "");
      return IBalancerVault(params.vault).swap(singleSwap, funds, 1, block.timestamp);
    }

    function balancerBatchSwap(address _vault, IBalancerVault.SwapKind _swapKind, address[] memory _route, bytes32[] memory pools, IBalancerVault.FundManagement memory _funds, uint256 _amountIn) internal returns (int256[] memory) {
      IBalancerVault.BatchSwapStep[] memory _swaps = new IBalancerVault.BatchSwapStep[](_route.length - 1); 
      int256[] memory limits = new int256[](_route.length);
      require(_route.length > 1, "Too short route");
      require(pools.length + 1 >= _route.length, "Too short pools");
      for (uint i; i < _route.length; i++) {
          if (i == 0) {
              limits[0] = int(_amountIn);
          }
          
          if (i == _route.length - 1) {
              limits[i] = 0; // TODO: it was -1, must be reviewed
          } else {
              _swaps[i] = IBalancerVault.BatchSwapStep({
                poolId: pools[i],
                assetInIndex: i,
                assetOutIndex: i + 1,
                amount: i == 0 ? _amountIn : 0,
                userData: ""
            });
          }
      }
      return IBalancerVault(_vault).batchSwap(_swapKind, _swaps, _route, _funds, limits, block.timestamp);
    }

  /******************************************************
   *                                                    *
   *                    VIEW FUNCTIONS                  *
   *                                                    *
   ******************************************************/

   // Get Balancer pool token balances
  function getPoolBalances(address _vault, bytes32 _poolId) internal view returns(uint256[] memory) {
    (,uint256[] memory balances,) = IBalancerVault(_vault).getPoolTokens(_poolId);
    return balances;
  }

  // Get Token index
  function getPoolTokenIndex(address _vault, bytes32 _poolId, address _token) internal view returns(uint256) {
    (address[] memory poolTokens,,) = IBalancerVault(_vault).getPoolTokens(_poolId);
    for (uint256 i = 0; i < poolTokens.length;) {
      if(poolTokens[i] == _token) {
        return i;
      }
      unchecked { ++i; }
    }
    revert("index not found");
  }

  // Get Balancer single amount to withdraw from Stable Pool from exact BPT amount
  function getTokenOutGivenExactBptInStable(address _vault, bytes32 _poolId, address _token, address _bptPool, uint lpBalance) internal view returns(uint256) {
    if (lpBalance == type(uint).max) {
      lpBalance = IERC20(_bptPool).balanceOf(address(this));
    }
    
    uint256[] memory poolTokenBalances = getPoolBalances(_vault, _poolId);
    (uint256 invariant, uint256 amp) = IStablePool(_bptPool).getLastInvariant();
    uint256 totalSupply = IStablePool(_bptPool).totalSupply();
    uint256 index = getPoolTokenIndex(_vault, _poolId, _token);
    uint256 swapFeePercentage = IStablePool(_bptPool).getSwapFeePercentage();

    return StableMath._calcTokenOutGivenExactBptIn(amp, poolTokenBalances, index, lpBalance, totalSupply, invariant, swapFeePercentage);
  }

  // Get Balancer amounts to withdraw from Weighted pools from exact BPT amount
  function getTokensOutGivenExactBptInWeighted(address _vault, bytes32 _poolId, address _bptPool, uint lpBalance) internal view returns(uint256[] memory) {
    if (lpBalance == type(uint).max) {
      lpBalance = IERC20(_bptPool).balanceOf(address(this));
    }
    
    uint256[] memory poolTokenBalances = getPoolBalances(_vault, _poolId);
    uint256 totalSupply = IStablePool(_bptPool).totalSupply();

    return WeightedMath._calcTokensOutGivenExactBptIn(poolTokenBalances, lpBalance, totalSupply);
  }

  function getPoolAddress(bytes32 poolId) internal pure returns (address) {
    // 12 byte logical shift left to remove the nonce and specialization setting. We don't need to mask,
    // since the logical shift already sets the upper bits to zero.
    return address(bytes20(poolId));
  }

  function balancerBatchQuote(address _vault, IBalancerVault.SwapKind _swapKind, address[] memory _route, bytes32[] memory pools, IBalancerVault.FundManagement memory _funds, uint256 _amountIn) internal returns (int256[] memory) {
    IBalancerVault.BatchSwapStep[] memory _swaps = new IBalancerVault.BatchSwapStep[](_route.length - 1); 
    require(_route.length > 1, "Too short route");
    require(pools.length + 1 >= _route.length, "Too short pools");
    for (uint i; i < _route.length; i++) {          
        if (i < _route.length - 1) {
            _swaps[i] = IBalancerVault.BatchSwapStep({
              poolId: pools[i],
              assetInIndex: i,
              assetOutIndex: i + 1,
              amount: i == 0 ? _amountIn : 0,
              userData: ""
          });
        }
    }
    return IBalancerVault(_vault).queryBatchSwap(_swapKind, _swaps, _route, _funds);
  }

}