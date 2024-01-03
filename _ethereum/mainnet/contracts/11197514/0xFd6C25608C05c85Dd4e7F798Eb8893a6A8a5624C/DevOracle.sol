// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IPriceOracleGetter.sol";

contract DevOracle is IPriceOracleGetter {

    mapping (address=>uint256) private _price;

    uint256 private price_;

    function setPrice(address underlying, uint newPrice) public {
        _price[underlying] = newPrice;
    }

    function getAssetPrice(address underlying) override external view returns (uint256) {
        return _price[underlying];
    }
}
