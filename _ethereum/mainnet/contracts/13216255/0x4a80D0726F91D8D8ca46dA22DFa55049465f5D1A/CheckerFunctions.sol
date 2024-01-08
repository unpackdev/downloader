// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./DSMath.sol";

// solhint-disable

// PoolOne/Whale checkers

function _isPoolOneOpen(uint256 _poolOneStartTime, uint256 _poolOneEndTime)
    view
    returns (bool)
{
    return
        _poolOneStartTime <= block.timestamp &&
        _poolOneEndTime > block.timestamp;
}

function _requirePoolOneIsOpen(
    uint256 _poolOneStartTime,
    uint256 _poolOneEndTime
) view {
    require(
        _isPoolOneOpen(_poolOneStartTime, _poolOneEndTime),
        "Pool One is not open"
    );
}

function _hasWhaleNeverBought(uint256 _gelLockedByWhaleAmt)
    pure
    returns (bool)
{
    return _gelLockedByWhaleAmt == 0;
}

function _requireWhaleNeverBought(uint256 _gelLockedByWhaleAmt) pure {
    require(
        _hasWhaleNeverBought(_gelLockedByWhaleAmt),
        "Whale had already bought GEL"
    );
}

function _isBoughtWithinWhaleCaps(
    uint256 _gelBought,
    uint256 _whaleMinGel,
    uint256 _whaleMaxGel
) pure returns (bool) {
    return _gelBought >= _whaleMinGel && _gelBought <= _whaleMaxGel;
}

function _requireBoughtWithinWhaleCaps(
    uint256 _gelBought,
    uint256 _whaleMinGel,
    uint256 _whaleMaxGel
) pure {
    require(
        _isBoughtWithinWhaleCaps(_gelBought, _whaleMinGel, _whaleMaxGel),
        "User buying amount is outside of Whale CAPs"
    );
}

function _isPoolOneCapExceeded(
    uint256 _totalGelCap,
    uint256 _marchandDeGlaceGelBalance,
    uint256 _totalGelLocked,
    uint256 _gelBought,
    uint256 _poolOneGelCap
) pure returns (bool) {
    return
        _totalGelCap -
            _marchandDeGlaceGelBalance +
            _totalGelLocked +
            _gelBought >
        _poolOneGelCap;
}

function _requirePoolOneCapNotExceeded(
    uint256 _totalGelCap,
    uint256 _marchandDeGlaceGelBalance,
    uint256 _totalGelLocked,
    uint256 _gelBought,
    uint256 _poolOneGelCap
) pure {
    require(
        !_isPoolOneCapExceeded(
            _totalGelCap,
            _marchandDeGlaceGelBalance,
            _totalGelLocked,
            _gelBought,
            _poolOneGelCap
        ),
        "Whale pool hasn't enough GEL Token."
    );
}

// PoolTwo/Dolphin checkers

function _isPoolTwoOpen(uint256 _poolTwoStartTime, uint256 _poolTwoEndTime)
    view
    returns (bool)
{
    return
        _poolTwoStartTime <= block.timestamp &&
        _poolTwoEndTime > block.timestamp;
}

function _requirePoolTwoIsOpen(
    uint256 _poolTwoStartTime,
    uint256 _poolTwoEndTime
) view {
    require(
        _isPoolTwoOpen(_poolTwoStartTime, _poolTwoEndTime),
        "Pool Two is not open"
    );
}

function _hasDolphinNeverBought(uint256 _gelBoughtByDolphin)
    pure
    returns (bool)
{
    return _gelBoughtByDolphin == 0;
}

function _requireDolphinNeverBought(uint256 _gelBoughtByDolphin) pure {
    require(
        _hasDolphinNeverBought(_gelBoughtByDolphin),
        "Dolphin had already bought GEL"
    );
}

function _isBoughtLteDolphinMax(uint256 _gelBought, uint256 _dolphinMaxGel)
    pure
    returns (bool)
{
    return _gelBought <= _dolphinMaxGel;
}

function _requireBoughtLteDolphinMax(uint256 _gelBought, uint256 _dolphinMaxGel)
    pure
{
    require(
        _isBoughtLteDolphinMax(_gelBought, _dolphinMaxGel),
        "User buying more than Dolphin max cap"
    );
}

function _getRemainingGel(
    uint256 _marchandDeGlaceGelBalance,
    uint256 _totalGelLocked
) pure returns (uint256) {
    return _marchandDeGlaceGelBalance - _totalGelLocked;
}

function _getBuyableRemainingGel(uint256 _remainingGel, uint256 _gelPerEth)
    pure
    returns (uint256)
{
    return _wmul((_remainingGel * 1e18) / _gelPerEth, _gelPerEth);
}

function _isSaleClosing(
    uint256 _marchandDeGlaceRemainingGel,
    uint256 _dolphinMinGel
) pure returns (bool) {
    return _marchandDeGlaceRemainingGel < _dolphinMinGel;
}

function _isBoughtEqBuyableRemaining(
    uint256 _gelBought,
    uint256 _marchandDeGlaceBuyableRemainingGel
) pure returns (bool) {
    return _gelBought == _marchandDeGlaceBuyableRemainingGel;
}

function _requireBoughtEqBuyableRemaining(
    uint256 _gelBought,
    uint256 _marchandDeGlaceBuyableRemainingGel
) pure {
    require(
        _isBoughtEqBuyableRemaining(
            _gelBought,
            _marchandDeGlaceBuyableRemainingGel
        ),
        "Last buyer should buy the exact buyable remaining."
    );
}

function _isBoughtGteDolphinMin(uint256 _gelBought, uint256 _dolphinMinGel)
    pure
    returns (bool)
{
    return _gelBought >= _dolphinMinGel;
}

function _requireBoughtGteDolphinMin(uint256 _gelBought, uint256 _dolphinMinGel)
    pure
{
    require(
        _isBoughtGteDolphinMin(_gelBought, _dolphinMinGel),
        "User buying less than Dolphin min cap"
    );
}

function _isBoughtLteRemaining(
    uint256 _gelBought,
    uint256 _marchandDeGlaceRemainingGel
) pure returns (bool) {
    return _gelBought <= _marchandDeGlaceRemainingGel;
}

function _requireBoughtLteRemaining(
    uint256 _gelBought,
    uint256 _marchandDeGlaceRemainingGel
) pure {
    require(
        _isBoughtLteRemaining(_gelBought, _marchandDeGlaceRemainingGel),
        "buyDolphin: GEL buy cap exceeded."
    );
}

// Whale unlock

function _requireNotAddressZero(address _to) pure {
    require(_to != address(0), "_to == AddressZero");
}

function _requireNotLocked(uint256 _lockUpEndTime) view {
    require(_lockUpEndTime < block.timestamp, "Still in lock time.");
}

function _requireHasGELToUnlock(uint256 _gelLockedByWhaleAmt) pure {
    require(_gelLockedByWhaleAmt > 0, "Whale has no GEL to unlock.");
}

// Whale unlock
