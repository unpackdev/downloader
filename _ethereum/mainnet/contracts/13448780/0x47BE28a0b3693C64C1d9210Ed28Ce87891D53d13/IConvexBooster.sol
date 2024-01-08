// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.2;

interface IConvexBooster {
    function depositAll(uint256 _pid, bool _stake) external returns (bool);
}