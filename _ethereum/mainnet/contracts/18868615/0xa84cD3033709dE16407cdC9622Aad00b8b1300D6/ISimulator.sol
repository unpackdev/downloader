// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ISimulator {
    function simulateV2(address router, address token) external;

    function simulateV3(
        address router,
        address token,
        address pair
    ) external;
}
