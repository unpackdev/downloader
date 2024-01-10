// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import "./IDCAHub.sol";
import "./TokenSorting.sol";
import "./Intervals.sol";
import "./ISharedTypes.sol";

/// @title Seconds Until Next Swap Library
/// @notice Provides functions to calculate how long users have to wait until a pair's next swap is available
library SecondsUntilNextSwap {
  /// @notice Returns how many seconds left until the next swap is available for a specific pair
  /// @dev _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _hub The address of the DCA Hub
  /// @param _tokenA One of the pair's tokens
  /// @param _tokenB The other of the pair's tokens
  /// @return The amount of seconds until next swap. Returns 0 if a swap can already be executed and max(uint256) if there is nothing to swap
  function secondsUntilNextSwap(
    IDCAHub _hub,
    address _tokenA,
    address _tokenB
  ) internal view returns (uint256) {
    (address __tokenA, address __tokenB) = TokenSorting.sortTokens(_tokenA, _tokenB);
    bytes1 _activeIntervals = _hub.activeSwapIntervals(__tokenA, __tokenB);
    bytes1 _mask = 0x01;
    uint256 _smallerIntervalBlocking;
    while (_activeIntervals >= _mask && _mask > 0) {
      if (_activeIntervals & _mask == _mask) {
        IDCAHub.SwapData memory _swapDataMem = _hub.swapData(_tokenA, _tokenB, _mask);
        uint32 _swapInterval = Intervals.maskToInterval(_mask);
        uint256 _nextAvailable = ((_swapDataMem.lastSwappedAt / _swapInterval) + 1) * _swapInterval;
        if (_swapDataMem.nextAmountToSwapAToB > 0 || _swapDataMem.nextAmountToSwapBToA > 0) {
          if (_nextAvailable <= block.timestamp) {
            return _smallerIntervalBlocking;
          } else {
            return _nextAvailable - block.timestamp;
          }
        } else if (_nextAvailable > block.timestamp) {
          _smallerIntervalBlocking = _smallerIntervalBlocking == 0 ? _nextAvailable - block.timestamp : _smallerIntervalBlocking;
        }
      }
      _mask <<= 1;
    }
    return type(uint256).max;
  }

  /// @notice Returns how many seconds left until the next swap is available for a list of pairs
  /// @dev Tokens in pairs may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _hub The address of the DCA Hub
  /// @param _pairs Pairs to check
  /// @return _seconds The amount of seconds until next swap for each of the pairs
  function secondsUntilNextSwap(IDCAHub _hub, Pair[] calldata _pairs) internal view returns (uint256[] memory _seconds) {
    _seconds = new uint256[](_pairs.length);
    for (uint256 i; i < _pairs.length; i++) {
      _seconds[i] = secondsUntilNextSwap(_hub, _pairs[i].tokenA, _pairs[i].tokenB);
    }
  }
}
