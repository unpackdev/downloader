// SPDX-License-Identifier: AGPLv3

pragma solidity ^0.8.13;

///@dev Snapshot Delegate registry so we can delegate voting to XYZ
interface IDelegateRegistry {
    function setDelegate(bytes32 id, address delegate) external;

    function clearDelegate(bytes32 id) external;

    function delegation(address, bytes32) external view returns (address);
}
