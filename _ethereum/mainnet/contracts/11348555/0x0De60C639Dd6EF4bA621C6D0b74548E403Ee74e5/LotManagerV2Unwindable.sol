// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./ILotManagerV2Unwindable.sol";
import "./LotManagerV2LotsHandler.sol";

abstract
contract LotManagerV2Unwindable is 
  LotManagerV2LotsHandler, 
  ILotManagerV2Unwindable {
  
  function _unwind(uint256 _amount) internal returns (uint256 _total) {
    (uint256 _ethLots, uint256 _wbtcLots) = balanceOfLots();
    require (_ethLots > 0 || _wbtcLots > 0, 'LotManagerV2Unwindable::_unwind::no-lots');

    bool areETHLotsUnlocked = hegicStakingETH.lastBoughtTimestamp(address(this)).add(hegicStakingETH.lockupPeriod()) <= block.timestamp;
    bool areWBTCLotsUnlocked = hegicStakingWBTC.lastBoughtTimestamp(address(this)).add(hegicStakingWBTC.lockupPeriod()) <= block.timestamp;
    require (areETHLotsUnlocked || areWBTCLotsUnlocked, 'LotManagerV2Unwindable::_unwind::no-unlocked-lots');
    _ethLots = areETHLotsUnlocked ? _ethLots : 0;
    _wbtcLots = areWBTCLotsUnlocked ? _wbtcLots : 0;
    uint256 _lotsToSell = _amount.div(LOT_PRICE).add(_amount.mod(LOT_PRICE) == 0 ? 0 : 1);
    require (_ethLots.add(_wbtcLots) >= _lotsToSell, 'LotManagerV2Unwindable::_unwind::not-enough-unlocked-lots');

    uint256 _totalSold = 0;

    if (_ethLots > 0) {
      _ethLots = _ethLots < _lotsToSell.sub(_totalSold) ? _ethLots : _lotsToSell.sub(_totalSold);
      _sellETHLots(_ethLots);
      _totalSold = _totalSold.add(_ethLots);
    }

    if (_wbtcLots > 0) {
      _wbtcLots = _wbtcLots < _lotsToSell.sub(_totalSold) ? _wbtcLots : _lotsToSell.sub(_totalSold);
      _sellWBTCLots(_wbtcLots);
      _totalSold = _totalSold.add(_wbtcLots);
    }

    require(_totalSold == _lotsToSell, 'LotManagerV2Unwindable::_unwind::not-enough-lots-sold');

    _total = _lotsToSell.mul(LOT_PRICE);

    require(_total >= _amount, 'LotManagerV2Unwindable::_unwind::not-enough-tokens-aquired');

    token.transfer(address(pool), _total);

    emit Unwound(_total);
  }
}
