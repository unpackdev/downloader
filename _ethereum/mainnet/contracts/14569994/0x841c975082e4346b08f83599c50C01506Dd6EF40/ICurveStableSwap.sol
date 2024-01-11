// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface ICurveStableSwap {
    function coins(uint256 i) external view returns (address);
}

interface ICurveStableSwap128 is ICurveStableSwap {
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;
}

interface ICurveStableSwap256 is ICurveStableSwap {
    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);
}
