// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICurve2CoinPool {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external;

    function remove_liquidity(uint256 burn_amount, uint256[2] calldata min_amounts) external;

    function remove_liquidity_one_coin(uint256 burn_amount, int128 i, uint256 min_amount) external;

    function calc_withdraw_one_coin(uint256 burn_amount, int128 i) external view returns (uint256);
}

interface ICurve3CoinPool {
    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external;

    function remove_liquidity(uint256 burn_amount, uint256[3] calldata min_amounts) external;
}

interface ICurvePoolUint256 {
    function balances(uint256 arg0) external view returns (uint256);

    function coins(uint256 arg0) external view returns (address);
}

interface ICurveEthPool {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external payable returns (uint256);
}
