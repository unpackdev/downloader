// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IVault {
    function receiveAEthFrom(address from, uint vol) external;
}
