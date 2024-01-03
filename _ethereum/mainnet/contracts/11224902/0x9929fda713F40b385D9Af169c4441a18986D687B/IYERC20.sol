// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
interface IYERC20 {
    function rebalance() external;
    function balanceOf(address account) external view returns (uint);
    function token() external view returns (address);
    function calcPoolValueInToken() external view returns (uint);
}