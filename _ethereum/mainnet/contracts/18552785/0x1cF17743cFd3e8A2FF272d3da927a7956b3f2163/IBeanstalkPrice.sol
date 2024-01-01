// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBeanstalkPrice {
    struct Pool {
        address pool;
        address[2] tokens;
        uint256[2] balances;
        uint256 price;
        uint256 liquidity;
        int256 deltaB;
        // uint256 lpSupply;
        uint256 lpUsd;
        uint256 lpBdv;
    }
    struct Prices {
        uint256 price;
        uint256 liquidity;
        int deltaB;
        Pool[] ps;
    }

    function price() external view returns (Prices memory p);
}
