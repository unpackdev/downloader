// SPDX-License-Identifier: GNU

pragma solidity >=0.5.0;

interface IWeth {
    function deposit() external payable;
    function withdraw(uint wad) external;
}
