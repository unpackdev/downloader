// Up It Go (UPITGO)
//
// https://upitgo.com
// https://twitter.com/upitgo
//
// 0.69%/0.69% (1% slippage)
//
// A dynamic liquidity experiment that provisions and deprovisions liquidity all in the contract
// and was built to trustlessly and explicitly punish full stackers, clip releasers, dumpers,
// jeets, and generally anyone who doesn't know how or desire to respect the technicals of a chart.
//
// The UPITGO contract caches pertinent data points and liquidity information on every transaction
// and will add to or remove liquidity over time in order to reward those respecting and buying
// into the chart and ultimately punish those who take actions to damage it. The contract will frontrun
// large sells with liquidity removal that increases price impact and reduces gains on said sells.
// The ETH & tokens retrieved from this liquidity removal are custodied in the contract and dynamically
// added back to the liquidity pool as buys come through and the chart goes back up over time.
//
// moonboy tldr:
//    - chart go up, liquidity go up, price impact down
//    - chart go down, liquidity go down, price impact up
//    - sell too much at once, rekt

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract UpItGo is ERC20 {
  using SafeERC20 for IERC20;

  uint256 constant PREC = 10 ** 18;
  address immutable UNISWAP_V2_POOL;
  IUniswapV2Router02 immutable UNISWAP_V2_ROUTER;

  uint256 _lpCurrent;
  uint256 _lpLastAdjusted;
  uint256 _tokensLastAdjusted;
  address _creator;
  uint256 _lt;
  bool _adjusting;
  bool _inactivty;

  event LiquidityAdded(
    uint256 _tokensDesired,
    uint256 _ethDesired,
    uint256 _tokensActual,
    uint256 _ethActual
  );
  event LiquidityRemoved(uint256 _tokensRemoved, uint256 _ethRemoved);

  constructor(IUniswapV2Router02 _uniRouter) ERC20('Up It Go', 'UPITGO') {
    _creator = _msgSender();
    UNISWAP_V2_ROUTER = _uniRouter;
    UNISWAP_V2_POOL = IUniswapV2Factory(UNISWAP_V2_ROUTER.factory()).createPair(
      address(this),
      UNISWAP_V2_ROUTER.WETH()
    );
    _mint(_msgSender(), 1_000_000 * 10 ** 18);
  }

  function _transfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal virtual override {
    _lt = block.timestamp;
    bool _buy = _from == UNISWAP_V2_POOL && _to != address(UNISWAP_V2_ROUTER);
    bool _sell = _to == UNISWAP_V2_POOL;
    uint256 _tax;
    if ((_buy || _sell) && !_inactivty) {
      _tax = (_amount * 69) / 10000; // 0.69%
      if (!_adjusting && _sell) {
        _adjusting = true;
        if (
          _lpLastAdjusted > 0 &&
          _lpCurrent > _lpLastAdjusted &&
          _tokensLastAdjusted > _amount
        ) {
          uint256 _lpPercToAdd = (PREC * _amount) / totalSupply();
          _addLp(_lpPercToAdd);
        } else {
          uint256 _percCheck = (10 * PREC * _amount) / totalSupply();
          uint256 _lpPercToRemove = _percCheck > PREC / 2
            ? PREC / 2
            : _percCheck;
          _removeLp(_lpPercToRemove);
        }
        _adjusting = false;
      }
      _storeLastAdjustedLiquidity(_amount);
      super._transfer(_from, address(this), _tax);
    }
    _storeCurrentLiquidity();
    super._transfer(_from, _to, _amount - _tax);
  }

  function _addLp(uint256 _percentage) internal {
    uint256 _tokensToAdd = (balanceOf(address(this)) * _percentage) / PREC;
    uint256 _ethToAdd = (address(this).balance * _percentage) / PREC;
    if (_tokensToAdd == 0 || _ethToAdd == 0) {
      return;
    }
    _approve(address(this), address(UNISWAP_V2_ROUTER), _tokensToAdd);
    (uint256 _actualAmountToken, uint256 _actualAmountETH, ) = UNISWAP_V2_ROUTER
      .addLiquidityETH{ value: _ethToAdd }(
      address(this),
      _tokensToAdd,
      0,
      0,
      address(this),
      block.timestamp
    );
    emit LiquidityAdded(
      _tokensToAdd,
      _ethToAdd,
      _actualAmountToken,
      _actualAmountETH
    );
  }

  function _removeLp(uint256 _percentage) internal {
    if (_lpBalance() == 0) {
      return;
    }
    uint256 _balBefore = balanceOf(address(this));
    uint256 _removingLp = (_lpBalance() * _percentage) / PREC;
    IERC20(UNISWAP_V2_POOL).approve(address(UNISWAP_V2_ROUTER), _removingLp);
    uint256 _amountETH = UNISWAP_V2_ROUTER
      .removeLiquidityETHSupportingFeeOnTransferTokens(
        address(this),
        _removingLp,
        0,
        0,
        address(this),
        block.timestamp
      );
    emit LiquidityRemoved(balanceOf(address(this)) - _balBefore, _amountETH);
  }

  function _storeCurrentLiquidity() internal {
    (uint256 _wethBal, uint256 _thisBal) = _currentLp();
    _lpCurrent = _thisBal == 0 ? 0 : (_wethBal * PREC) / _thisBal;
  }

  function _storeLastAdjustedLiquidity(uint256 _tokens) internal {
    (uint256 _wethBal, uint256 _thisBal) = _currentLp();
    _lpLastAdjusted = _thisBal == 0 ? 0 : (_wethBal * PREC) / _thisBal;
    _tokensLastAdjusted = _tokens;
  }

  function _currentLp() internal view returns (uint256, uint256) {
    uint256 _wethBal = IERC20(UNISWAP_V2_ROUTER.WETH()).balanceOf(
      UNISWAP_V2_POOL
    );
    uint256 _thisBal = balanceOf(UNISWAP_V2_POOL);
    return (_wethBal, _thisBal);
  }

  function _lpBalance() internal view returns (uint256) {
    return IERC20(UNISWAP_V2_POOL).balanceOf(address(this));
  }

  // if the project is inactive and has no buys/sells/transfers for 3+ hours,
  // we will allow withdrawal of LP and ETH to the creator.
  // As long as the project remains active and pushing, this cannot happen.
  function inactivityWithdrawal() external {
    require(block.timestamp > _lt + 3 hours, 'ACT');
    uint256 _lpBal = IERC20(UNISWAP_V2_POOL).balanceOf(address(this));
    if (_lpBal > 0) {
      IERC20(UNISWAP_V2_POOL).safeTransfer(_creator, _lpBal);
    }
    if (address(this).balance > 0) {
      (bool _sent, ) = payable(_creator).call{ value: address(this).balance }(
        ''
      );
      require(_sent);
    }
    _inactivty = true;
  }

  receive() external payable {}
}
