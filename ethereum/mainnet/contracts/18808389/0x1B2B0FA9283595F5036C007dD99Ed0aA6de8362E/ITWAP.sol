// SPDX-License-Identifier: MIT
pragma solidity >=0.7.4;


interface ITWAP {
    function getPrice(address tokenIn, address tokenOut) external view returns (uint);
}