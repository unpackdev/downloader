// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

interface IDelegate {
    function delegation(address, bytes32) external view returns (address);

    function setDelegate(bytes32 id, address delegate) external;

    function clearDelegate(bytes32 id) external;
}