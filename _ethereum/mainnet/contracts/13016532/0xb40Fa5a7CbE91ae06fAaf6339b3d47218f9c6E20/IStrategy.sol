// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./IUniswapV3Pool.sol";

interface IStrategy {

    // add config
    function addConfig(bytes calldata data) external;

    // change config
    function changeConfig(bytes calldata data) external;

    // change direction
    function changeDirection(uint8) external;

    // get position liq | amount0 | amount1
    function getTotalAmounts() external view returns(uint128, uint256, uint256);

    // check reBalance status
    function checkReBalanceStatus() external view returns (bool);

    // update commission
    function updateCommission(IUniswapV3Pool) external;

    // collect commission
    function collectCommission(IUniswapV3Pool, address) external returns(uint256, uint256);

    // Add Liquidity to Earn Commission
    function mining() external;

    // Withdraw Liquidity
    function stopMining(uint128, address) external returns(uint256, uint256);

    // Passive Reset Interval
    function reBalance() external returns (bool, uint256, uint256, int24, int24);

}
