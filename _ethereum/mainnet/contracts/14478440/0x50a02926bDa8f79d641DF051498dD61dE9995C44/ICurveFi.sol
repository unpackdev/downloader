// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

interface ICurveFi {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function calc_token_amount(uint256[2] calldata amounts, bool is_deposit) external view returns (uint256);
}
