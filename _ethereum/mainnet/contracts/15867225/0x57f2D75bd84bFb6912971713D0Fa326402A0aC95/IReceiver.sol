// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IReceiver {
    function notify() external;
    function configure() external;
}
