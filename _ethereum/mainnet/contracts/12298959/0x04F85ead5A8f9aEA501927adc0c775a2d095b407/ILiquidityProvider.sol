// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./IUniswapV2Pair.sol";
import "./IERC20.sol";

interface ILiquidityProvider {
    function addLiquidityETH(
        address,
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) external payable returns (uint256);

    function addLiquidityETHByPair(
        IUniswapV2Pair,
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) external payable returns (uint256);

    function addLiquidity(
        address,
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        address,
        uint256,
        uint256
    ) external payable returns (uint256);

    function addLiquidityByPair(
        IUniswapV2Pair,
        uint256,
        uint256,
        uint256,
        uint256,
        address,
        uint256,
        uint256
    ) external payable returns (uint256);

    function removeLiquidityETH(
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        address,
        uint256,
        uint256,
        uint8
    ) external returns (uint256[3] memory);

    function removeLiquidityETHByPair(
        IUniswapV2Pair,
        uint256,
        uint256,
        uint256,
        uint256,
        address,
        uint256,
        uint256,
        uint8
    ) external returns (uint256[3] memory);

    function removeLiquidityETHWithPermit(
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        address,
        uint256,
        uint256,
        uint8,
        uint8,
        bytes32,
        bytes32
    ) external returns (uint256[3] memory);

    function removeLiquidity(
        address,
        address,
        uint256,
        uint256[2] memory,
        uint256[2] memory,
        address,
        uint256,
        uint256,
        uint8
    ) external returns (uint256[3] memory);

    function removeLiquidityByPair(
        IUniswapV2Pair,
        uint256,
        uint256[2] memory,
        uint256[2] memory,
        address,
        uint256,
        uint256,
        uint8
    ) external returns (uint256[3] memory);

    function removeLiquidityWithPermit(
        address,
        address,
        uint256,
        uint256[2] memory,
        uint256[2] memory,
        address,
        uint256,
        uint256,
        uint8,
        uint8,
        bytes32,
        bytes32
    ) external returns (uint256[3] memory);
}
