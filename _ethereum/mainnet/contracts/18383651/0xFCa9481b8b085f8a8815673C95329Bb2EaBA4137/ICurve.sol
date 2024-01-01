// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ICurve {
    // add liquidity

    // 0
    function add_liquidity(
        uint256[3] calldata _amounts,
        uint256 _min_mint_amount
    ) external payable;

    // 1
    function add_liquidity(
        uint256[3] calldata _amounts,
        uint256 _min_mint_amount,
        bool _use_underlying_or_use_eth
    ) external payable;

    // 2
    function add_liquidity(
        uint256[2] calldata _amounts,
        uint256 _min_mint_amount
    ) external payable;

    // 3
    function add_liquidity(
        uint256[4] calldata _amounts,
        uint256 _min_mint_amount
    ) external;

    // 4
    function add_liquidity(
        uint256[2] calldata _amounts,
        uint256 _min_mint_amount,
        bool _use_underlying_or_use_eth
    ) external payable;

    // 5 meta zap
    function add_liquidity(
        address _pool,
        uint256[4] calldata _amounts,
        uint256 _min_mint_amount
    ) external;

    // 6 meta zap
    function add_liquidity(
        address _pool,
        uint256[3] calldata _amounts,
        uint256 _min_mint_amount
    ) external;

    // remove liquidity one coin

    // 0
    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received
    ) external;

    // 1
    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received,
        bool _use_underlying
    ) external;

    // 2
    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        uint256 i,
        uint256 _min_received,
        bool _use_eth
    ) external;

    // 3
    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        uint256 i,
        uint256 _min_received
    ) external;

    // 4 meta zap
    function remove_liquidity_one_coin(
        address _pool,
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received
    ) external;

    // calc token amount

    // 0
    function calc_token_amount(
        uint256[3] calldata _amounts,
        bool _is_deposit
    ) external view returns (uint256);

    // 1
    function calc_token_amount(
        uint256[2] calldata _amounts,
        bool _is_deposit
    ) external view returns (uint256);

    // 2
    function calc_token_amount(
        uint256[4] calldata _amounts,
        bool _is_deposit
    ) external view returns (uint256);

    // 3
    function calc_token_amount(
        uint256[2] calldata _amounts
    ) external view returns (uint256);

    // 4 meta zap
    function calc_token_amount(
        address _pool,
        uint256[4] calldata _amounts,
        bool _is_deposit
    ) external view returns (uint256);

    // 5 meta zap
    function calc_token_amount(
        address _pool,
        uint256[3] calldata _amounts,
        bool _is_deposit
    ) external view returns (uint256);

    // cal withdraw one coin

    // 0
    function calc_withdraw_one_coin(
        uint256 _burn_amount,
        int128 i
    ) external view returns (uint256);

    // 1
    function calc_withdraw_one_coin(
        uint256 _burn_amount,
        int128 i,
        bool _use_underlying
    ) external view returns (uint256);

    // 2
    function calc_withdraw_one_coin(
        uint256 _burn_amount,
        uint256 i
    ) external view returns (uint256);

    // 3
    function calc_withdraw_one_coin(
        address _pool,
        uint256 _burn_amount,
        int128 i
    ) external view returns (uint256);

    // get exchange amount;

    //

    // 1
    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    // 4
    function get_dy(
        address pool,
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    // 5
    function get_dy_underlying(
        address pool,
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    // 6
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    // 2
    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    // 3
    function get_dy_underlying(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    ///
    // exchange

    // 3
    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable returns (uint256);

    // 2
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable returns (uint256);

    // 5
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable returns (uint256);

    // 1
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth
    ) external payable returns (uint256);

    // 4
    function exchange(
        address pool,
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable returns (uint256);

    // 6
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable returns (uint256);

    function coins(uint256 index) external view returns (address);

    function underlying_coins(uint256 index) external view returns (address);
}
