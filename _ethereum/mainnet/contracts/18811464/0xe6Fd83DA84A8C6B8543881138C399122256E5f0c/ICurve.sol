//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IPool {
    function underlying_coins(int128 index) external view returns (address);

    function coins(int128 index) external view returns (address);
}

interface IPoolV3 {
    function underlying_coins(uint256 index) external view returns (address);

    function coins(uint256 index) external view returns (address);
}

interface ICurvePool {
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external;

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external;

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns(uint256);
}

interface IPancakeStableSwap {
    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 minDy
    ) external;

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 minDy
    ) external;

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns(uint256);
}

interface ICurveEthPool {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external payable;

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns(uint256);
}

interface ICompoundPool {
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external;

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external;

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns(uint256);
}