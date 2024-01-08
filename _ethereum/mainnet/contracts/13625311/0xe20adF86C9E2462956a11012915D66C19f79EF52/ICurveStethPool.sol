// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface ICurveStethPool {
    // add liquidity (ETH) to receive back steCRV
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external payable returns (uint256);

    // remove liquidity (steCRV) to recieve back ETH
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external returns (uint256);
}
