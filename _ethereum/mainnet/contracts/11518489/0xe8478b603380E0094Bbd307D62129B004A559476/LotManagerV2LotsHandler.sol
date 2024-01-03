// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./SafeMath.sol";

import "./ILotManagerV2LotsHandler.sol";

import "./LotManagerV2ProtocolParameters.sol";

abstract
contract LotManagerV2LotsHandler is 
  LotManagerV2ProtocolParameters, 
  ILotManagerV2LotsHandler {

  using SafeMath for uint256;

  function balanceOfUnderlying() public override view returns (uint256 _underlyingBalance) {
    (uint256 _ethLots, uint256 _wbtcLots) = balanceOfLots();
    return _ethLots.add(_wbtcLots).mul(LOT_PRICE);
  }

  function balanceOfLots() public override view returns (uint256 _ethLots, uint256 _wbtcLots) {
    return (
      hegicStakingETH.balanceOf(address(this)),
      hegicStakingWBTC.balanceOf(address(this))
    );
  }

  function profitOfLots() public override view returns (uint256 _ethProfit, uint256 _wbtcProfit) {
    return (
      hegicStakingETH.profitOf(address(this)),
      hegicStakingWBTC.profitOf(address(this))
    );
  }

  function _buyLots(uint256 _ethLots, uint256 _wbtcLots) internal returns (bool) {
    // Get allowance
    uint256 allowance = token.allowance(address(pool), address(this));
    // Check if Allowance exceeds lot contract cost
    uint256 lotsCosts = _ethLots.add(_wbtcLots).mul(LOT_PRICE);
    require (allowance >= lotsCosts, 'LotManagerV2LotsHandler::_buyLots::not-enough-allowance');
    // Buy lot by transfering tokens
    token.transferFrom(address(pool), address(this), lotsCosts);

    // Buys Lot(s) (defaults buys ETH lot)
    if (_ethLots > 0) _buyETHLots(_ethLots);
    if (_wbtcLots > 0) _buyWBTCLots(_wbtcLots);

    // Transfer unused tokens(underlying) back to the pool
    token.transfer(address(pool), token.balanceOf(address(this)));

    return true;
  }

  function _buyETHLots(uint256 _ethLots) internal {
    // Allow hegicStakingETH to spend allowance
    token.approve(address(hegicStakingETH), 0);
    token.approve(address(hegicStakingETH), _ethLots * LOT_PRICE);
    hegicStakingETH.buy(_ethLots);
    emit ETHLotBought(_ethLots);
  }

  function _buyWBTCLots(uint256 _wbtcLots) internal {
    // Allow hegicStakingWBTC to spend allowance
    token.approve(address(hegicStakingWBTC), 0);
    token.approve(address(hegicStakingWBTC), _wbtcLots * LOT_PRICE);
    hegicStakingWBTC.buy(_wbtcLots);
    emit WBTCLotBought(_wbtcLots);
  }

  function _sellLots(uint256 _ethLots, uint256 _wbtcLots) internal returns (bool) {
    // Sells Lot(s) used for unwinding/rebalancing
    (uint256 _ownedETHLots, uint256 _ownedWBTCLots) = balanceOfLots();
    require (_ethLots <= _ownedETHLots && _wbtcLots <= _ownedWBTCLots, 'LotManagerV2LotsHandler::_sellLots::not-enough-lots');
    if (_ethLots > 0) _sellETHLots(_ethLots);
    if (_wbtcLots > 0) _sellWBTCLots(_wbtcLots);

    // Transfer all underlying back to pool
    token.transfer(address(pool), token.balanceOf(address(this)));

    return true;
  }

  function _sellETHLots(uint256 _eth) internal {
    hegicStakingETH.sell(_eth);
    emit ETHLotSold(_eth);
  }

  function _sellWBTCLots(uint256 _wbtc) internal {
    hegicStakingWBTC.sell(_wbtc);
    emit WBTCLotSold(_wbtc);
  }

  function _rebalanceLots(uint _ethLots, uint256 _wbtcLots) internal returns (bool) {
    (uint256 _ownedETHLots, uint256 _ownedWBTCLots) = balanceOfLots();
    require(
      _ethLots.add(_wbtcLots) == _ownedETHLots.add(_ownedWBTCLots) &&
      _ethLots != _ownedETHLots &&
      _wbtcLots != _ownedWBTCLots, 
      'LotManagerV2LotsHandler::_rebalanceLots::not-rebalancing-lots'
    );

    uint256 lotsDelta;
    if (_ethLots > _ownedETHLots) {
      lotsDelta = _ethLots.sub(_ownedETHLots);
      _sellWBTCLots(lotsDelta);
      _buyETHLots(lotsDelta);
    } else if (_wbtcLots > _ownedWBTCLots) {
      lotsDelta = _wbtcLots.sub(_ownedWBTCLots);
      _sellETHLots(lotsDelta);
      _buyWBTCLots(lotsDelta);
    }

    emit LotsRebalanced(_ethLots, _wbtcLots);
    return true;
  }
}