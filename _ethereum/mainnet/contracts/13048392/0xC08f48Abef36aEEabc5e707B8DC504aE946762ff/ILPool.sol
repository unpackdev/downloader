//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ILPool {
    function balanceOf(address owner) external view returns (uint);
    function releaseTime() external view returns (uint);
}
