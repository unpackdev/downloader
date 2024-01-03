// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ISushiswapV2Factory {
    function allPairsLength() external view returns (uint);
    function allPairs(uint) external view returns (address pair);
}
