//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IDepositer {
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external returns (uint256);

    function remove_liquidity(uint256 _token_amount, uint256[4] calldata _min_amounts)
        external
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function add_liquidity(uint256[3] calldata _token_amounts, uint256 _min_amount) external;
}
