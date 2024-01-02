// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

contract DutchAuction {
    uint256 internal _initialPrice;
    uint256 internal _minPrice;
    uint256 internal _step;
    uint256 public startedAt;
    uint256 public finalPrice;

    constructor(
        uint256 initialPrice,
        uint256 minPrice,
        uint256 step,
        uint256 startTime
    ) {
        _initialPrice = initialPrice;
        _minPrice = minPrice;
        _step = step;
        startedAt = startTime;
        finalPrice = minPrice;
    }

    function currentPrice() public view returns (uint256) {
        if (block.timestamp < startedAt) return _initialPrice;

        uint256 delta = block.timestamp - startedAt;
        uint256 thirtyMinuteDecrease = (delta / (30 * 60)) * _step;
        if (thirtyMinuteDecrease >= _initialPrice) {
            return _minPrice;
        }
        uint256 price = _initialPrice - thirtyMinuteDecrease;
        if (price < _minPrice) {
            return _minPrice;
        }
        return price;
    }
}
