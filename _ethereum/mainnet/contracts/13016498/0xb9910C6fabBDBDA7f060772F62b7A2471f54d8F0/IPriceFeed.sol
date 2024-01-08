// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPriceFeed {
    function getToken() external view returns (address);
    function getPrice() external view returns (uint);
}
