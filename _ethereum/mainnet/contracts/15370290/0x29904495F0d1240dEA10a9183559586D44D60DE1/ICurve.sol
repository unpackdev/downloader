//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface ICrvPool {
    function get_dy(
        int128 i,
        int128 j,
        uint256 amount
    ) external view returns (uint256);
    
    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 amount
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 amount,
        uint256 minReturn
    ) external returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 amount,
        uint256 minReturn
    ) external returns (uint256);

    function coins(int128 index) external view returns (address);

    function coins(uint256 index) external view returns (address);

    function calc_withdraw_one_coin(uint256 amount, uint256 index) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 amount,
        uint256 index,
        uint256 minReturn
    ) external view returns (uint256);

    function balances(uint256 index) external view returns (uint256);
}
