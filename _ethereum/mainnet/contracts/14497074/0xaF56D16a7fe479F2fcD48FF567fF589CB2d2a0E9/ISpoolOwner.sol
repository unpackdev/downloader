// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ISpoolOwner {
    function isSpoolOwner(address user) external view returns(bool);
}