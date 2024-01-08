// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IUniswapV3OracleWrapper {
    function period() external view returns (uint32 _period);
}
