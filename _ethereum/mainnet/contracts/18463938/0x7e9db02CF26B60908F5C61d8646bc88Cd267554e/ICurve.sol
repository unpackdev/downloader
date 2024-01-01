// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./IERC20.sol";

interface ICurve is IERC20 {
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function coins(uint256) external view returns (address);

    // N_COINS = 2
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external payable returns (uint256);

    function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 min_received)
        external
        returns (uint256);

    function remove_liquidity(uint256 _burn_amount, uint256[2] memory _min_amounts)
        external
        returns (uint256[2] memory);

    // Perform an exchange between two coins
    function exchange(
        // ETH-ALETH
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy
    ) external payable returns (uint256);

    // Perform an exchange between two coins
    function exchange(
        // CRV-ETH and CVX-ETH
        uint256 i,
        uint256 j,
        uint256 _dx,
        uint256 _min_dy,
        bool use_eth
    ) external payable returns (uint256);

    function balances(uint256) external view returns (uint256);

    function price_oracle() external view returns (uint256);

    function get_balances() external view returns (uint256, uint256);

    function owner() external view returns (address);
}
