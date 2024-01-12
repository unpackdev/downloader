// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IUnderlyingContainer {
    function underlying() external view returns (address);
}