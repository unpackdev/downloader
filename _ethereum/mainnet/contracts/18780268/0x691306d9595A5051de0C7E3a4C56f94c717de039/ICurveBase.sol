// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

interface ICurveBase {
    //variable names from https://curve.readthedocs.io/exchange-deposits.html#DepositZap.add_liquidity

    function calc_token_amount(uint256[2] memory _amounts, bool _is_deposit) external view returns (uint256);

    function calc_token_amount(uint256[3] memory _amounts, bool _is_deposit) external view returns (uint256);

    function calc_token_amount(uint256[4] memory _amounts, bool _is_deposit) external view returns (uint256);

    // BASE POOLS
    function add_liquidity(uint256[2] memory _underlying_amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[3] memory _underlying_amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[4] memory _underlying_amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[5] memory _underlying_amounts, uint256 min_mint_amount) external;

    // META POOLS
    function add_liquidity(address _pool, uint256[2] memory _underlying_amounts, uint256 min_mint_amount) external;

    function add_liquidity(address _pool, uint256[3] memory _underlying_amounts, uint256 min_mint_amount) external;

    function add_liquidity(address _pool, uint256[4] memory _underlying_amounts, uint256 min_mint_amount) external;

    function add_liquidity(address _pool, uint256[5] memory _underlying_amounts, uint256 min_mint_amount) external;

    function remove_liquidity_one_coin(uint256 _amount, uint256 i, uint256 _min_underlying_amount) external;

    function remove_liquidity_one_coin(
        uint256 _amount,
        int128 i,
        uint256 _min_underlying_amount
    ) external returns (uint256);

    // BASE POOLS
    function remove_liquidity(uint256 _amount, uint256[2] memory _min_underlying_amounts) external;

    function remove_liquidity(uint256 _amount, uint256[3] memory _min_underlying_amounts) external;

    function remove_liquidity(uint256 _amount, uint256[4] memory _min_underlying_amounts) external;

    function remove_liquidity(uint256 _amount, uint256[5] memory _min_underlying_amounts) external;

    // META POOLS
    function remove_liquidity(address _pool, uint256 _amount, uint256[2] memory _min_underlying_amounts) external;

    function remove_liquidity(address _pool, uint256 _amount, uint256[3] memory _min_underlying_amounts) external;

    function remove_liquidity(address _pool, uint256 _amount, uint256[4] memory _min_underlying_amounts) external;

    function remove_liquidity(address _pool, uint256 _amount, uint256[5] memory _min_underlying_amounts) external;

    // META POOLS
    function remove_liquidity_one_coin(
        address _pool,
        uint256 _amount,
        int128 i,
        uint256 _min_underlying_amount
    ) external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
}

interface ICurveNative {
    // POOLS THAT ACCEPT ETH
    function add_liquidity(uint256[2] memory _underlying_amounts, uint256 min_mint_amount) external payable;

    function add_liquidity(uint256[3] memory _underlying_amounts, uint256 min_mint_amount) external payable;

    function remove_liquidity_one_coin(uint256 _amount, int128 i, uint256 _min_underlying_amount) external;
}
