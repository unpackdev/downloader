// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

interface ICurvePool {
    function get_virtual_price() external view returns (uint256 price);

    function price_oracle() external view returns (uint256);

    function add_liquidity(uint256[2] memory amounts, uint256 _min_mint_amount) external;
}