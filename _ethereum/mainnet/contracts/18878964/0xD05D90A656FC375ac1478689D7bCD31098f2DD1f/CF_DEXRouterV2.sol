// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./CF_Ownable.sol";
import "./CF_Common.sol";
import "./CF_ERC20.sol";

abstract contract CF_DEXRouterV2 is CF_Ownable, CF_Common, CF_ERC20 {
  event SwapAndLiquify(uint256 tokenAmount, uint256 ethAmount, uint256 liquidity);
  event SwappedTokensForETH(uint256 tokenAmount, uint256 ethAmount);
  event SwappedTokensForERC20(address token, uint256 token0Amount, uint256 token1Amount);
  event SetDEXRouter(address indexed router, address indexed pair, address receiver);
  event RenouncedDEXRouterV2();

  modifier lockSwapping {
    _swapping = true;
    _;
    _swapping = false;
  }

  /// @notice Permanently renounce and prevent the owner from being able to update the DEX features
  /// @dev Existing settings will continue to be effective
  function renounceDEXRouterV2() external onlyOwner {
    _renounced.DEXRouterV2 = true;

    emit RenouncedDEXRouterV2();
  }

  /// @notice Sets the DEX router and where to receive the LP tokens
  /// @param router Address of the DEX router
  /// @param receiver Address of the LP tokens receiver
  function setDEXRouter(address router, address receiver) external onlyOwner returns (address) {
    require(!_renounced.DEXRouterV2);

    return _setDEXRouter(router, receiver);
  }

  function _setDEXRouter(address router, address receiver) internal returns (address) {
    require(router != address(0));

    if (_dex.router != router) {
      IDEXRouterV2 _router = IDEXRouterV2(router);
      IDEXFactoryV2 factory = IDEXFactoryV2(_router.factory());
      address WETH = _router.WETH();
      address pair = factory.getPair(address(this), WETH);

      if (pair == address(0)) { pair = factory.createPair(address(this), WETH); }

      _dex = DEXRouterV2(router, pair, WETH, receiver);
    }

    if (receiver != _dex.receiver) { _dex.receiver = receiver; }

    emit SetDEXRouter(router, _dex.pair, receiver);

    return _dex.pair;
  }

  /// @notice Returns the DEX router currently in use
  function getDEXRouter() external view returns (address) {
    return _dex.router;
  }

  /// @notice Returns the trading pair
  function getDEXPair() external view returns (address) {
    return _dex.pair;
  }

  /// @notice Returns address of the LP tokens receiver
  function getDEXReceiver() external view returns (address) {
    return _dex.receiver;
  }

  /// @notice Returns address of the reflection token
  function getReflectionToken() external view returns (address) {
    return address(_reflectionToken);
  }

  /// @notice Checks the status of the auto-swapping feature
  function isSwapEnabled() external view returns (bool) {
    return _swapEnabled;
  }

  /// @notice Checks whether the token can be traded through the assigned DEX
  function isTradingEnabled() external view returns (bool) {
    return _tradingEnabled > 0;
  }

  /// @notice Assign the excess token balance of the Smart-Contract to liquidity
  function liquifyExcess() external onlyOwner {
    require(_swapEnabled && !_swapping);

    unchecked {
      uint256 assigned = _amountForTaxDistribution + _amountForLiquidity;

      require(_balance[address(this)] > assigned);

      uint256 excess = _balance[address(this)] - assigned;

      _amountForLiquidity += excess;
    }

    _autoSwap(false);
  }

  /// @notice Swaps the assigned amount for liquidity and taxes to the corresponding token
  /// @dev Will only be executed if there is no ongoing swap or tax distribution and the min. threshold has been reached unless forced
  /// @param force Ignore the min. threshold amount
  function autoSwap(bool force) external onlyOwner {
    require(_swapEnabled && !_swapping && !_distributing);

    _autoSwap(force);
  }

  function _autoSwap(bool force) internal lockSwapping {
    if (!_swapEnabled) { return; }

    unchecked {
      if (force || ((address(_reflectionToken) == _dex.WETH ? _amountForTaxDistribution : 0) + _amountForLiquidity / 2 >= _minSwapAmount && _balance[address(this)] >= (address(_reflectionToken) == _dex.WETH ? _amountForTaxDistribution : 0) + _amountForLiquidity)) {
        uint256 tokenAmountForLiquidity = _amountForLiquidity / 2;
        uint256 ethBalance = address(this).balance;
        address[] memory pathToSwapExactTokensForETH = new address[](2);
        pathToSwapExactTokensForETH[0] = address(this);
        pathToSwapExactTokensForETH[1] = _dex.WETH;

        _approve(address(this), _dex.router, (address(_reflectionToken) == _dex.WETH ? _amountForTaxDistribution : 0) + tokenAmountForLiquidity);

        try IDEXRouterV2(_dex.router).swapExactTokensForETHSupportingFeeOnTransferTokens((address(_reflectionToken) == _dex.WETH ? _amountForTaxDistribution : 0) + tokenAmountForLiquidity, 0, pathToSwapExactTokensForETH, address(this), block.timestamp + 1) {
          _lastSwap = _timestamp();

          if (_amountForLiquidity > 0) { _amountForLiquidity /= 2; }

          uint256 ethAmount = address(this).balance - ethBalance;

          emit SwappedTokensForETH((address(_reflectionToken) == _dex.WETH ? _amountForTaxDistribution : 0) + tokenAmountForLiquidity, ethAmount);

          if (ethAmount > 0) {
            uint256 ethForLiquidity = ethAmount;

            if (address(_reflectionToken) == _dex.WETH) {
              ethForLiquidity = _percentage(ethAmount, tokenAmountForLiquidity >= _amountForTaxDistribution ? (100 * uint256(_denominator)) - ((uint256(_denominator) * _amountForTaxDistribution * 100) / (tokenAmountForLiquidity + _amountForTaxDistribution)) : (uint256(_denominator) * tokenAmountForLiquidity * 100) / (tokenAmountForLiquidity + _amountForTaxDistribution));

              _amountSwappedForTaxDistribution += _amountForTaxDistribution;
              _amountForTaxDistribution = 0;
              _ethForTaxDistribution += ethAmount - ethForLiquidity;
            }

            if (tokenAmountForLiquidity > 0 && ethForLiquidity > 0) {
              _approve(address(this), _dex.router, tokenAmountForLiquidity);

              try IDEXRouterV2(_dex.router).addLiquidityETH{ value: ethForLiquidity }(address(this), tokenAmountForLiquidity, 0, 0, _dex.receiver, block.timestamp + 1) returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) {
                emit SwapAndLiquify(amountToken, amountETH, liquidity);

                _amountForLiquidity = 0;
              } catch {
                _approve(address(this), _dex.router, 0);
              }
            }
          }
        } catch {
          _approve(address(this), _dex.router, 0);
        }
      }

      if (force || (address(_reflectionToken) != address(this) && address(_reflectionToken) != _dex.WETH && _amountForTaxDistribution >= _minSwapAmount && _balance[address(this)] >= _amountForTaxDistribution)) {
        uint256 reflectionTokenBalance = _reflectionToken.balanceOf(address(this));
        address[] memory pathToSwapExactTokensForERC20 = new address[](3);
        pathToSwapExactTokensForERC20[0] = address(this);
        pathToSwapExactTokensForERC20[1] = _dex.WETH;
        pathToSwapExactTokensForERC20[2] = address(_reflectionToken);

        _reflectionToken.approve(_dex.router, _amountForTaxDistribution);

        try IDEXRouterV2(_dex.router).swapExactTokensForTokensSupportingFeeOnTransferTokens(_amountForTaxDistribution, 0, (pathToSwapExactTokensForERC20), address(this), block.timestamp + 1) {
          emit SwappedTokensForERC20(address(_reflectionToken), _amountForTaxDistribution, reflectionTokenBalance - _reflectionToken.balanceOf(address(this)));

          _amountSwappedForTaxDistribution += _amountForTaxDistribution;
          _amountForTaxDistribution = 0;
          _reflectionTokensForTaxDistribution += reflectionTokenBalance - _reflectionToken.balanceOf(address(this));
        } catch {
          _reflectionToken.approve(_dex.router, 0);
        }
      }
    }
  }

  /// @notice Sets the desired ERC-20 reflection token
  /// @dev If other token than WETH is specified, the pair WETH-token must already exist
  /// @param token Address of the ERC-20 token
  function setReflection(address token) external onlyOwner {
    require(!_renounced.DEXRouterV2);

    _setReflection(token);
  }

  function _setReflection(address token) internal {
    require(token == address(0) || token == address(this) || token == _dex.WETH || IDEXFactoryV2(IDEXRouterV2(_dex.router).factory()).getPair(_dex.WETH, token) != address(0), "No Pair");

    if (token == address(0)) { token == address(this); }

    _reflectionToken = IERC20(token);
  }

  /// @notice Returns the minimum percentage of the total supply in the Smart-Contract balance to trigger auto swap
  function getMinSwapPercent() external view returns (uint24) {
    return _minSwapPercent;
  }

  /// @notice Sets the minimum percentage of the total supply in the Smart-Contract balance to trigger auto swap
  /// @param percent Desired percentage, multiplied by denominator
  function setMinSwapPercent(uint24 percent) external onlyOwner {
    require(!_renounced.DEXRouterV2);
    require(percent >= 1 && percent <= 1000, "0.001% to 1%");

    _setMinSwapPercent(percent);
  }

  function _setMinSwapPercent(uint24 percent) internal {
    _minSwapPercent = percent;
    _minSwapAmount = _percentage(_totalSupply, uint256(percent));
  }

  /// @notice Enables or disables the auto swap function
  /// @param status True to enable, False to disable
  function setSwapStatus(bool status) external onlyOwner {
    require(!_renounced.DEXRouterV2);
    require(!status || _dex.router != address(0), "No DEX");

    _swapEnabled = status;
  }

  /// @notice Enables or disables the trading capability via the DEX set up
  /// @param status True to enable, False to disable
  function setTradingStatus(bool status) external onlyOwner {
    require(!_renounced.DEXRouterV2);

    _tradingEnabled = status ? _timestamp() : 0;
  }
}
