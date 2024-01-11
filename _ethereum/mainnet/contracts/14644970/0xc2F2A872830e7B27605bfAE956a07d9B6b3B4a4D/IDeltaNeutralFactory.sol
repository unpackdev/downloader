pragma solidity 0.8.6;

// TODO License
// SPDX-License-Identifier: UNLICENSED

interface IDeltaNeutralFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB, uint minBps, uint maxBps) external returns (address pair);

    // function setFeeTo(address) external; TODO
    // function setFeeToSetter(address) external; TODO

    function MAX_UINT() external pure returns (uint);
    function weth() external view returns (address);
    function uniV2Factory() external view returns (address);
    function uniV2Router() external view returns (address);
//    function fuse() external view returns (address); TODO
    function comptroller() external view returns (address);
    function registry() external view returns (address payable);
    function userFeeVeriForwarder() external view returns (address);
}
