// https://peapods.finance

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Ownable.sol";
import "./IUniswapV3Pool.sol";
import "./ISwapRouter.sol";
import "./IERC20Metadata.sol";
import "./IV3TwapUtilities.sol";
import "./DecentralizedIndex.sol";

contract UnweightedIndex is DecentralizedIndex, Ownable {
  using SafeERC20 for IERC20;

  address constant V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
  address immutable V3_WETH_STABLE_POOL;

  uint256 public rebalanceSlippage = 10; // 10 == 1%, 100 == 10%
  uint256 public rebalanceMinSwapUSDX96 = FixedPoint96.Q96; // $1

  event Rebalance();

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _bondFee,
    uint256 _debondFee,
    address[] memory _pools,
    address _lpRewardsToken,
    address _v2Router,
    address _v3StableWETHPool,
    address _dai,
    bool _stakeRestriction,
    IV3TwapUtilities _v3TwapUtilities
  )
    DecentralizedIndex(
      _name,
      _symbol,
      _bondFee,
      _debondFee,
      _lpRewardsToken,
      _v2Router,
      _dai,
      _stakeRestriction,
      _v3TwapUtilities
    )
  {
    indexType = IndexType.UNWEIGHTED;
    V3_WETH_STABLE_POOL = _v3StableWETHPool;
    address _weth9 = IUniswapV2Router02(_v2Router).WETH();
    for (uint256 _i; _i < _pools.length; _i++) {
      IUniswapV3Pool _pool = IUniswapV3Pool(_pools[_i]);
      uint256 _basePriceUSDX96 = _v3TwapUtilities.getPoolPriceUSDX96(
        _pools[_i],
        _v3StableWETHPool,
        _weth9
      );
      address _token0 = _pool.token0();
      address _nonNativeToken = _pools[_i] == _v3StableWETHPool
        ? _weth9
        : _token0 == _weth9
        ? _pool.token1()
        : _token0;
      indexTokens.push(
        IndexAssetInfo({
          token: _nonNativeToken,
          basePriceUSDX96: _basePriceUSDX96,
          weighting: 0,
          c1: _pools[_i],
          q1: 0
        })
      );
      _fundTokenIdx[_nonNativeToken] = _i;
      _isTokenInIndex[_nonNativeToken] = true;
    }
  }

  function _swapIndexToken0ForToken1(
    address _token0,
    address _token1,
    uint256 _price0USDX96,
    uint256 _price1USDX96,
    uint256 _valueNeededUSDX96
  ) internal {
    uint256 _amountIn = (_valueNeededUSDX96 *
      10 ** IERC20Metadata(_token0).decimals()) / _price0USDX96;
    if (_amountIn == 0) {
      return;
    }
    uint256 _amountOutMin = (_valueNeededUSDX96 *
      10 ** IERC20Metadata(_token1).decimals()) / _price1USDX96;
    uint256 _token0Bal = IERC20(_token0).balanceOf(address(this));
    uint256 _amountInFinal = _token0Bal < _amountIn ? _token0Bal : _amountIn;
    uint256 _amountOutMinFinal = (_amountInFinal * _amountOutMin) / _amountIn;
    if (_amountInFinal == 0 || _amountOutMinFinal == 0) {
      return;
    }
    _v3SwapTokensForTokens(
      _token0,
      _token1,
      _amountInFinal,
      (_amountOutMinFinal * (1000 - rebalanceSlippage)) / 1000
    );
  }

  function _v3SwapTokensForTokens(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    uint256 _amountOutMin
  ) internal {
    IUniswapV3Pool _pool0 = IUniswapV3Pool(
      indexTokens[_fundTokenIdx[_tokenIn]].c1
    );
    IUniswapV3Pool _pool1 = IUniswapV3Pool(
      indexTokens[_fundTokenIdx[_tokenOut]].c1
    );
    IERC20(_tokenIn).safeIncreaseAllowance(V3_ROUTER, _amountIn);
    bytes memory _path = abi.encodePacked(
      _tokenIn,
      _pool0.fee(),
      WETH,
      _pool1.fee(),
      _tokenOut
    );
    if (_tokenIn == WETH) {
      _path = abi.encodePacked(_tokenIn, _pool1.fee(), _tokenOut);
    } else if (_tokenOut == WETH) {
      _path = abi.encodePacked(_tokenIn, _pool0.fee(), _tokenOut);
    }
    ISwapRouter(V3_ROUTER).exactInput(
      ISwapRouter.ExactInputParams({
        path: _path,
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: _amountIn,
        amountOutMinimum: _amountOutMin
      })
    );
  }

  function _rebalance() internal {
    uint256[] memory _balances = new uint256[](indexTokens.length);
    uint256[] memory _pricesUSDX96 = new uint256[](indexTokens.length);
    uint256[] memory _currentValueUSDX96 = new uint256[](indexTokens.length);
    uint256[] memory _perTokenRatioInIdxX96 = new uint256[](indexTokens.length);
    uint256 _totalValueUSDX96;
    uint256 _ratioSumX96;
    for (uint256 _i; _i < indexTokens.length; _i++) {
      (
        _balances[_i],
        _pricesUSDX96[_i],
        _currentValueUSDX96[_i]
      ) = _getTokenBalPriceAndCurrentValueUSDX96(indexTokens[_i]);
      _totalValueUSDX96 += _currentValueUSDX96[_i];
      _perTokenRatioInIdxX96[_i] =
        (FixedPoint96.Q96 * _pricesUSDX96[_i]) /
        indexTokens[_i].basePriceUSDX96;
      _ratioSumX96 += _perTokenRatioInIdxX96[_i];
    }

    for (uint256 _i; _i < indexTokens.length; _i++) {
      uint256 _valuePerIUSDX96 = (_totalValueUSDX96 *
        _perTokenRatioInIdxX96[_i]) / _ratioSumX96;
      if (
        _currentValueUSDX96[_i] < _valuePerIUSDX96 &&
        _valuePerIUSDX96 - _currentValueUSDX96[_i] > rebalanceMinSwapUSDX96
      ) {
        for (uint256 _j; _j < indexTokens.length; _j++) {
          if (_i == _j) {
            continue;
          }
          uint256 _valuePerJUSDX96 = (_totalValueUSDX96 *
            _perTokenRatioInIdxX96[_j]) / _ratioSumX96;
          if (
            _currentValueUSDX96[_j] > _valuePerJUSDX96 &&
            _currentValueUSDX96[_j] - _valuePerJUSDX96 > rebalanceMinSwapUSDX96
          ) {
            _swapIndexToken0ForToken1(
              indexTokens[_j].token,
              indexTokens[_i].token,
              _pricesUSDX96[_j],
              _pricesUSDX96[_i],
              _currentValueUSDX96[_j] - _valuePerJUSDX96
            );
            (
              _balances[_j],
              _pricesUSDX96[_j],
              _currentValueUSDX96[_j]
            ) = _getTokenBalPriceAndCurrentValueUSDX96(indexTokens[_j]);
            (
              _balances[_i],
              _pricesUSDX96[_i],
              _currentValueUSDX96[_i]
            ) = _getTokenBalPriceAndCurrentValueUSDX96(indexTokens[_i]);
            if (_currentValueUSDX96[_i] >= _valuePerIUSDX96) {
              break;
            }
          }
        }
      }
    }
    emit Rebalance();
  }

  function _getTokenBalPriceAndCurrentValueUSDX96(
    IndexAssetInfo memory _poolConf
  )
    internal
    view
    returns (uint256 _balance, uint256 _priceX96, uint256 _valueUSDX96)
  {
    _priceX96 = V3_TWAP_UTILS.getPoolPriceUSDX96(
      _poolConf.c1,
      V3_WETH_STABLE_POOL,
      WETH
    );
    _balance = IERC20(_poolConf.token).balanceOf(address(this));
    _valueUSDX96 =
      (_balance * _priceX96) /
      10 ** IERC20Metadata(_poolConf.token).decimals();
  }

  function rebalance() external lock {
    _rebalance();
  }

  function bond(address _token, uint256 _amount) external override lock noSwap {
    require(_isTokenInIndex[_token], 'INVALIDTOKEN');
    _transferAndValidate(IERC20(_token), _msgSender(), _amount);
    uint256 _tokenPriceUSDX96 = V3_TWAP_UTILS.getPoolPriceUSDX96(
      indexTokens[_fundTokenIdx[_token]].c1,
      V3_WETH_STABLE_POOL,
      WETH
    );
    (, uint256 _currentIdxPriceUSDX96) = getIdxPriceUSDX96();
    uint256 _tokensMinted = (_tokenPriceUSDX96 * _amount * 10 ** decimals()) /
      _currentIdxPriceUSDX96 /
      10 ** IERC20Metadata(_token).decimals();
    uint256 _feeTokens = _isFirstIn() ? 0 : (_tokensMinted * BOND_FEE) / 10000;
    _mint(_msgSender(), _tokensMinted - _feeTokens);
    if (_feeTokens > 0) {
      _mint(address(this), _feeTokens);
    }
    _rebalance();
    emit Bond(_msgSender(), _token, _amount, _tokensMinted);
  }

  function debond(
    uint256 _amount,
    address[] memory _token,
    uint8[] memory _percentage // 1 - 100%
  ) external override lock noSwap {
    require(_token.length == _percentage.length, 'INSYNC');
    uint256 _amountAfterFee = _isLastOut(_amount)
      ? _amount
      : (_amount * (10000 - DEBOND_FEE)) / 10000;
    _transfer(_msgSender(), address(this), _amount);
    _burn(address(this), _amountAfterFee);
    (, uint256 _currentIdxPriceUSDX96) = getIdxPriceUSDX96();
    uint256 _usdToDebondX96 = (_currentIdxPriceUSDX96 * _amountAfterFee) /
      10 ** decimals();
    uint8 _totalPercentage;
    for (uint256 _i; _i < _token.length; _i++) {
      require(_isTokenInIndex[_token[_i]], 'INVALIDTOKEN');
      _totalPercentage += _percentage[_i];
      uint256 _usdX96 = (_usdToDebondX96 * _percentage[_i]) / 100;
      uint256 _poolIdx = _fundTokenIdx[_token[_i]];
      IERC20(_token[_i]).safeTransfer(
        _msgSender(),
        (_usdX96 * 10 ** IERC20Metadata(_token[_i]).decimals()) /
          V3_TWAP_UTILS.getPoolPriceUSDX96(
            indexTokens[_poolIdx].c1,
            V3_WETH_STABLE_POOL,
            WETH
          )
      );
    }
    require(_totalPercentage == 100, 'TOTAL');
    _rebalance();
    emit Debond(_msgSender(), _amount);
  }

  function getTokenPriceUSDX96(
    address _token
  ) external view override returns (uint256) {
    require(_isTokenInIndex[_token], 'EXISTS');
    uint256 _idx = _fundTokenIdx[_token];
    return
      V3_TWAP_UTILS.getPoolPriceUSDX96(
        indexTokens[_idx].c1,
        V3_WETH_STABLE_POOL,
        WETH
      );
  }

  function getIdxPriceUSDX96() public view override returns (uint256, uint256) {
    uint256 _ratioSumX96;
    for (uint256 _i; _i < indexTokens.length; _i++) {
      _ratioSumX96 +=
        (FixedPoint96.Q96 *
          V3_TWAP_UTILS.getPoolPriceUSDX96(
            indexTokens[_i].c1,
            V3_WETH_STABLE_POOL,
            WETH
          )) /
        indexTokens[_i].basePriceUSDX96;
    }
    return (_ratioSumX96, _ratioSumX96 / indexTokens.length);
  }

  function setRebalanceSlippage(uint256 _slippage) external onlyOwner {
    rebalanceSlippage = _slippage;
  }

  function setRebalanceMinSwapUSDX96(uint256 _usdX96) external onlyOwner {
    rebalanceMinSwapUSDX96 = _usdX96;
  }
}
