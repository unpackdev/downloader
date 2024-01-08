//SPDX-License-Identifier: CC-BY-SA-4.0

pragma solidity ^0.8.0;

import "./Ownable.sol";

contract Prices is Ownable {

    uint public priceBaseBlockT;
    uint[10] private _colorNextPrices;
    uint[10] private _priceDurations;
    uint public COLORPrice = 10 ether;
    uint public slot = 0;

    constructor() Ownable() {}

    function getAllPricesData(
    ) view external returns (
        uint[10] memory,
        uint[10] memory
    )  {
        return (
        _colorNextPrices,
        _priceDurations
        );
    }

    function initializePrices(
        uint[10] memory prices,
        uint[10] memory durations
    ) public onlyOwner {
        priceBaseBlockT = block.timestamp;
        slot = 0;

        COLORPrice = prices[0];
        _colorNextPrices = prices;
        _priceDurations = durations;
    }

    function reducePrice() public {
        // Blocks ahead of starting sale block;
        require(slot >= 0 && slot <= 9, "No more reductions, ;)");
        require(block.timestamp - priceBaseBlockT > _priceDurations[slot], "Not yet ;)");

        slot = slot + 1;
        COLORPrice = _colorNextPrices[slot];
        priceBaseBlockT = block.timestamp;
    }
}

interface IColors {
    function balanceOf(address owner) external view returns (uint256);
}
