// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IBankStorage {
    function paused() external view returns (bool);

    function underlying() external view returns (address);
}
