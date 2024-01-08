// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWSOHM {
    function wOHMTosOHM(uint256 wohm) external view returns(uint256);
    function sOHMTowOHM(uint256 wsohm) external view returns(uint256);
}
