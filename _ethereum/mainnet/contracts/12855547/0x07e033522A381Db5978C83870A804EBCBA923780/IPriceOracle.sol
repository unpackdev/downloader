// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IPriceOracle {
    function getPrice(address token) external view returns (uint);
}
