// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface ICurvePool1 is IERC20 {
    function get_p() external view returns (uint256);

    function get_dy(int128 from, int128 to, uint256 from_amount) external view returns (uint256);

    function exchange(int128 from, int128 to, uint256 from_amount, uint256 min_to_amount)
        external
        payable
        returns (uint256 amount);

    function price_oracle() external view returns (uint256 price);
}

interface ICurvePool2 is IERC20 {
    function get_p() external view returns (uint256);

    function get_dy(uint256 from, uint256 to, uint256 from_amount) external view returns (uint256);

    // Exchange using WETH by default
    function exchange(uint256 from, uint256 to, uint256 from_amount, uint256 min_to_amount)
        external
        payable
        returns (uint256 amount);

    // Exchange using ETH by default
    function exchange_underlying(uint256 from, uint256 to, uint256 from_amount, uint256 min_to_amount)
        external
        payable
        returns (uint256 amount);

    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount, bool use_eth, address receiver)
        external
        payable
        returns (uint256 shares);

    function remove_liquidity(uint256 shares, uint256[3] memory minAmounts, bool use_eth, address receiver)
        external
        payable
        returns (uint256[3] memory amounts);

    function calc_token_amount(uint256[3] memory amounts, bool deposit) external view returns (uint256 amount);

    function totalSupply() external view returns (uint256 totalSupply);

    function balances(uint256 token) external view returns (uint256 balance);
}
