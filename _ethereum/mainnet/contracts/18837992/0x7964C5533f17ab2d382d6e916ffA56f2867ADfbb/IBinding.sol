// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.23;

interface IBinding {

    error InvalidTransferOwnership();

    function bindCryptar(address cryptar) external;

    function transferOwnership(address newAdmin) external;
}
