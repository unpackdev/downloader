// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface ICurveFi {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(
        // renBTC pool
        uint256[2] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        // sBTC pool
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        // bUSD pool
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata amounts) external;
    function remove_liquidity(uint256 _amount, uint256[3] calldata amounts) external;
    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;
}

interface Zap {
    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    ) external;
}
