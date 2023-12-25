// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ISimulator {
    function simulateV2(address token) external;

    function simulateV3(address token, address pair) external;
}
