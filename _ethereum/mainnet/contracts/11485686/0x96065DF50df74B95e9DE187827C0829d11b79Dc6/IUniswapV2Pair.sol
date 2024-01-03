// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    function mint(address to) external returns(uint256);
    function totalSupply() external view returns(uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
