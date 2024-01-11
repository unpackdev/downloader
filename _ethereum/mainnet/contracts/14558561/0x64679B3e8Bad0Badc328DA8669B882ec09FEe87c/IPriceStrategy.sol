//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IPriceStrategy {
    function getPrice(uint256 num) external view returns (uint256);
    function setPrice(uint256 initial, uint256 step) external;
}
