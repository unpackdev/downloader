// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;

interface IGate {

    function getCost() external view returns (uint ethCost);

    function passThruGate() external payable;
}
