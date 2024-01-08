// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ITimelockTarget {
    function setGov(address _gov) external;
}
