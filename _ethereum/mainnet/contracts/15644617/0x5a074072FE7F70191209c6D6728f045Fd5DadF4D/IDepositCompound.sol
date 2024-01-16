// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

// Curve DepositCompound contract interface
interface IDepositCompound {
    function underlying_coins(int128 arg0) external view returns (address);

    function token() external view returns (address);

    function add_liquidity(uint256[2] calldata uamounts, uint256 min_mint_amount) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata min_uamounts) external;

    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_uamount, bool donate_dust) external;
}