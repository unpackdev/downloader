// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICrvPool {
    function calc_token_amount(uint256[2] memory amounts) external view returns (uint256);

    function last_prices() external view returns (uint256);

    function price_oracle() external view returns (uint256);

    function price_scale() external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external payable;

    function remove_liquidity(uint256 amount, uint256[2] memory min_amounts) external payable;

    function remove_liquidity_one_coin(uint256 token_amount, uint256 i, uint256 min_amount) external payable;

    function token() external view returns (address);

    function exchange(
        uint256 i, //index tokenIn
        uint256 j, //index tokenOut
        uint256 dx, //amountIn
        uint256 min_dy, //amountOut
        bool use_eth
    ) external payable;

    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);

    function coins(uint256 i) external view returns (address);

    function balanceOf(address arg0) external view returns (uint256);

    function last_prices_timestamp() external view returns (uint256);
}

interface ITriCrvPool {
    function calc_token_amount(uint256[2] memory amounts) external view returns (uint256);

    function last_prices(uint256 k) external view returns (uint256);

    function price_oracle(uint256 k) external view returns (uint256);

    function price_scale(uint256 k) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount, bool _use_underlying) external payable;

    function token() external view returns (address);

    function exchange(
        uint256 i, //index tokenIn
        uint256 j, //index tokenOut
        uint256 dx, //amountIn
        uint256 min_dy, //amountOut
        bool use_eth
    ) external payable;

    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);

    function coins(uint256 i) external view returns (address);

    function balanceOf(address arg0) external view returns (uint256);

    function last_prices_timestamp() external view returns (uint256);
}
