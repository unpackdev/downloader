
pragma solidity ^0.6.0;

import "./IStatisticProvider.sol";

contract DevPriceProvider is IStatisticProvider {

    uint256 private _price;

    function setPrice(uint newPrice) public {
        _price = newPrice;
    }

    function current() override public view returns (uint256) {
        return _price;
    }
}
