// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface ITreasury {
    function get_total_amounts() external view returns (uint amount0, uint amount1, uint[] memory totalAmounts0, uint[] memory totalAmounts1, uint[] memory currentAmounts0, uint[] memory currentAmounts1);
    function get_tokens(uint reward, uint requestedAmount0, uint requestedAmount1, address to) external returns (uint sentToken, uint sentBlxm);
    function add_liquidity(uint amountBlxm, uint amountToken, address to) external;
}