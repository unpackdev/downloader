// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IFactory {

    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

}
