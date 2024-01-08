// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

interface IHyperDex {
    function getFunctionImplementation(bytes4 _signature) external returns (address);
}