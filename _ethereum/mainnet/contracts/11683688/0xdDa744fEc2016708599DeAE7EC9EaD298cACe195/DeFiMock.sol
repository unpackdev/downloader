// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import "./INestQuery.sol";

contract DeFiMock {

    INestQuery _NestQuery;

    struct PriceInfo {
        address token;
        uint256 atHeight;
        uint256 ethAmount;
        uint256 tokenAmount;
    }
    PriceInfo[] public prices;

    constructor(address Oracle) public {
        _NestQuery = INestQuery(Oracle);
    }

    function simu() public {
        return;
    }

    function query(address token) payable public {
        (uint256 ethAmount, uint256 tokenAmount, uint256 bn) = _NestQuery.query{value:msg.value}(token, msg.sender);
        prices.push(PriceInfo(token, bn, ethAmount, tokenAmount));
    }

    // function queryOracle(address token) payable public {
    //     uint128[] memory data = _NestOracle.queryPriceList{value:msg.value}(token, uint8(4), msg.sender);
    //     for (uint256 i=0; i<data.length; i=i+3) {
    //         _prices.push(PriceInfo(token, data[i], data[i+1], data[i+2]));
    //     }
    // }

    function lengthOfPrices() public view returns (uint256) {
        return prices.length;
    }

    function priceByIndex(uint256 index) public view returns (PriceInfo memory) {
        return prices[index];
    }
    
}