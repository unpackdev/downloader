// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface ISwapQueryHelper {

    function coinQuote(address token, uint256 tokenAmount)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function factory() external pure returns (address);

    function COIN() external pure returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function hasPool(address token) external view returns (bool);

    function getReserves(
        address pair
    ) external view returns (uint256, uint256);

    function pairFor(
        address tokenA,
        address tokenB
    ) external pure returns (address);

    function getPathForCoinToToken(address token) external pure returns (address[] memory);

}
