//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import "./IERC20.sol";


interface IOneUp is IERC20 {
    function burn(uint256 amount) external;
    function setTradingStart(uint256 time) external;
    function mint(address to, uint256 value) external;
}