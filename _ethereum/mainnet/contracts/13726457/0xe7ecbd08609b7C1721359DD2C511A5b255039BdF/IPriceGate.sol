// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

interface IPriceGate {

    function getCost(uint) external view returns (uint ethCost);

    function passThruGate(uint, address) external payable;
}
