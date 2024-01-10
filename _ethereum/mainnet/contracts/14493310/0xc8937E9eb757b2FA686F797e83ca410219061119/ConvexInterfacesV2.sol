// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "./ConvexInterfaces.sol";
import "./IConvexBoosterV2.sol";

interface ICurveSwapV2 is ICurveSwap {
    // function remove_liquidity_one_coin(
    //     uint256 _token_amount,
    //     int128 _i,
    //     uint256 _min_amount
    // ) external override;

    function remove_liquidity_one_coin(
        address _pool,
        uint256 _burn_amount,
        int128 _i,
        uint256 _min_amount
    ) external;

    // function coins(uint256 _coinId) external view returns(address); in ICurveSwap
    function coins(int128 _coinId) external view returns (address);

    function balances(uint256 _coinId) external view override returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _tokenAmount, int128 _tokenId)
        external
        view
        returns (uint256);

    /* factory */
    function calc_withdraw_one_coin(
        address _pool,
        uint256 _tokenAmount,
        int128 _tokenId
    ) external view returns (uint256);
}
