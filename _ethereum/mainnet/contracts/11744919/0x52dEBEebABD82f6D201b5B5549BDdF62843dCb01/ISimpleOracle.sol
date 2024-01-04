// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ISimpleOracle {
    function getPrice() external view returns (uint256 amountOut);
    // function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestamp);
}
