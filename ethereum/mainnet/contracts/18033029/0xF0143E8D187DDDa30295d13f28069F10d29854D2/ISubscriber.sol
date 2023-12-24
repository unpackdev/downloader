// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.16;

interface ISubscriber {
    function notify(bytes32 _event, bytes calldata _data) external;
}
