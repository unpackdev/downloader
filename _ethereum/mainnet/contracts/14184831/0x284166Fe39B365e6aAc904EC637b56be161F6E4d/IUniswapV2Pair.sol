// SPDX-License-Identifier: ISC

pragma solidity ^0.8.9;

interface IUniswapV2Pair {
    function balanceOf(address owner) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}
