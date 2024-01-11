//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IPriceStrategy.sol";

contract PriceStrategyExp is IPriceStrategy, Ownable {
    uint256 private _step;
    uint256 private _initial;

    constructor() {
        setPrice(3e16, 2000); // 0.03eth, +0.03 every 2000
    }

    function setPrice(uint256 initial, uint256 step) public override onlyOwner {
        require(step != 0, "step assert");
        _initial = initial;
        _step = step;
    }

    function getPrice(uint256 num) external override view returns (uint256)
    {
        uint256 steps = num / _step;
        return _initial * (steps + 1);
    }
}
