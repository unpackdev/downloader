//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

interface ICurvePool {
    function coins(uint256 _i) external view returns (address);
    function lp_token() external view returns (address);
    function get_virtual_price() external view returns (uint256);

    function exchange(int128 _i, int128 _j, uint256 _dx, uint256 _minDy) external returns (uint256);
    function add_liquidity(uint256[2] calldata _amounts, uint256 _minMintAmount) external payable returns (uint256);
    function remove_liquidity_one_coin(uint256 _amount, int128 _i, uint256 _minAmount) external payable returns (uint256);
}
