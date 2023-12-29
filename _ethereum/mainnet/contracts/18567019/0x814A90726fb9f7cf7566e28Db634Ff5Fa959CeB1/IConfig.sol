// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IConfig {
    function getGlobalFrozenState() external view returns (bool);

    function getProtocolFee() external view returns (int128);

    function getProtocolTreasury() external view returns (address);

    function setGlobalFrozen(bool) external;

    function updateProtocolTreasury(address) external;

    function updateProtocolFee(int128) external;
}
