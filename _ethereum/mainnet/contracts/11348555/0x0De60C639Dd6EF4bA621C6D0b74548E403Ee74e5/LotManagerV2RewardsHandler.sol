// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./SafeMath.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

import "./ILotManagerV2RewardsHandler.sol";
import "./IWETH9.sol";

import "./LotManagerV2ProtocolParameters.sol";
import "./LotManagerV2LotsHandler.sol";

abstract
contract LotManagerV2RewardsHandler is 
  LotManagerV2ProtocolParameters, 
  LotManagerV2LotsHandler,
  ILotManagerV2RewardsHandler {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  receive() external payable { }

  function claimableRewards() public override view returns (uint256) {
    (uint256 _ethProfit, uint256 _wbtcProfit) = profitOfLots();

    if (_wbtcProfit > 0) {
      _ethProfit = _ethProfit.add(_getAmountOut(_wbtcProfit, wbtc, weth));
    }

    if (_ethProfit == 0) return 0;

    return _getAmountOut(_ethProfit, weth, address(token));
  }
    
  function _claimRewards() internal returns (uint256 _totalRewards) {
    (uint256 _ethProfit, uint256 _wbtcProfit) = profitOfLots();
    require(_ethProfit > 0 || _wbtcProfit > 0, 'LotManagerV2RewardsHandler::_claimRewards::no-proft-available');

    // Claim x888 Lot Rewards in WBTC if there is profit
    if (_wbtcProfit > 0) {
      hegicStakingWBTC.claimProfit();

      if (_ethProfit == 0) {
        // Swaps WBTC for Hegic
        _swapWBTCForToken();
      } else {
        // Swaps WBTC for WETH
        _swapWBTCForWETH();
      }
    }

    // If there is ETH profit
    if (_ethProfit > 0) {
      // Claim it
      hegicStakingETH.claimProfit();

      // Swap eth for weth
      IWETH9(weth).deposit{value:payable(address(this)).balance}();

      // Swap all WETH for Hegic
      _swapWETHForToken();
    }

    // Gets amount of tokens as rewards
    _totalRewards = token.balanceOf(address(this));

    // Take fee in HEGIC
    uint256 _fee = _totalRewards.mul(performanceFee).div(FEE_PRECISION).div(100);

    // Deposit fee in Pool to get zHEGIC
    token.approve(address(pool), 0);
    token.approve(address(pool), _fee);
    pool.deposit(_fee);

    // Transfer zHegic to feeRecipient
    IERC20 zToken = IERC20(pool.getZToken());
    zToken.transfer(address(zTreasury), zToken.balanceOf(address(this)));
    zTreasury.distributeEarnings();

    // Transfer HEGIC _totalRewards minus _fee to pool
    token.transfer(address(pool), _totalRewards.sub(_fee));

    emit RewardsClaimed(_totalRewards, _fee);
  }

  function _swapWBTCForWETH() internal {
    uint256 _wbtcBalance = IERC20(wbtc).balanceOf(address(this));

    address[] memory _path = new address[](2);
    _path[0] = wbtc;
    _path[1] = weth;

    // Swap wbtc for weth
    _swap(_wbtcBalance, _path);
  }

  function _swapWBTCForToken() internal {
    uint256 _wbtcBalance = IERC20(wbtc).balanceOf(address(this));

    address[] memory _path = new address[](3);
    _path[0] = wbtc;
    _path[1] = weth;
    _path[2] = address(token);

    // Swap wbtc for token
    _swap(_wbtcBalance, _path);
  }

  function _swapWETHForToken() internal {
    uint256 _wethBalance = IERC20(weth).balanceOf(address(this));

    address[] memory _path = new address[](2);
    _path[0] = weth;
    _path[1] = address(token);

    // Swap weth for token
    _swap(_wethBalance, _path);
  }

  function _swap(
    uint256 _amount,
    address[] memory _path
  ) internal {
    // Approve given erc20
    IERC20(_path[0]).safeApprove(uniswapV2, 0);
    IERC20(_path[0]).safeApprove(uniswapV2, _amount);
    // Swap it
    IUniswapV2Router02(uniswapV2).swapExactTokensForTokens(
      _amount,
      0,
      _path,
      address(this),
      now.add(1800)
    );
  }

  function _getAmountOut(
    uint256 _amountIn,
    address _fromToken,
    address _toToken
  ) internal view returns (uint256) {
    IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(uniswapV2);
    IUniswapV2Factory uniswapV2Factory = IUniswapV2Factory(uniswapV2Router.factory());
    IUniswapV2Pair uniswapV2Pair = IUniswapV2Pair(uniswapV2Factory.getPair(_fromToken, _toToken));
    (uint112 _reserve0, uint112 _reserve1,) = uniswapV2Pair.getReserves();
    (uint112 _reserveFromToken, uint112 _reserveToToken) = (_fromToken < _toToken) ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
    return uniswapV2Router.getAmountOut(_amountIn, _reserveFromToken, _reserveToToken);
  }
}
