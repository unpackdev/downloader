// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICurveMetaPool {
    function get_price_cumulative_last() external view returns (uint256[2] memory);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx,
        uint256[2] memory balances
    ) external view returns (uint256);

    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);

    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256[2] memory balances
    ) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);
}
