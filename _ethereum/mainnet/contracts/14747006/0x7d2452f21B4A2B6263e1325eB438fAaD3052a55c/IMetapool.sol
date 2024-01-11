//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IMetapool {
    function add_liquidity(uint256[2] calldata call_data_amounts, uint256 min_mint_amount) external returns (uint256);
}
