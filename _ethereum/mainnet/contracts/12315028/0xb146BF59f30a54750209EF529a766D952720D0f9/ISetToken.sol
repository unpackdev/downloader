// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

interface ISetToken {

    function balanceOf(address owner) external view returns (uint);

    function getTotalComponentRealUnits(address _component) external view returns(uint);
}