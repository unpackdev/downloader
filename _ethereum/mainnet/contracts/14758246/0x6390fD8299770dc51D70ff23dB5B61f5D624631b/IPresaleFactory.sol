// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPresaleFactory {
    function registerPresale (address _presaleAddress) external;
    function presaleIsRegistered(address _presaleAddress) external view returns (bool);
}