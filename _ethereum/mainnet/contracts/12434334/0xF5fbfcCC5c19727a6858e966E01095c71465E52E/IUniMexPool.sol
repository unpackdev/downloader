// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface IUniMexPool {
    function borrow(uint256 _amount) external;
    function distribute(uint256 _amount) external;
    function distributeCorrections(uint256 _amount) external;
    function repay(uint256 _amount) external returns (bool);
    function distributeCorrection(uint256 _amount) external returns (bool);
}

