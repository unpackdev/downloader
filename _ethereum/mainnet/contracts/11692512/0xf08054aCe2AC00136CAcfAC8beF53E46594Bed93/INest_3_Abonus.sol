// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.0;

interface INest_3_Abonus {

    function getETHNum(address token) external view returns (uint256); 

    function turnOutAllEth(uint256 amount, address target) external;

}