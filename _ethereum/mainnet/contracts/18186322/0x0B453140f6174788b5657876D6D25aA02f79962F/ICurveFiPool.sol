// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface ICurveFiPool {
    function coins(uint256 i) external view returns (address);
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
    ) external;
    function price_oracle() external view returns (uint256);
    function last_prices_timestamp() external view returns (uint256);
}
