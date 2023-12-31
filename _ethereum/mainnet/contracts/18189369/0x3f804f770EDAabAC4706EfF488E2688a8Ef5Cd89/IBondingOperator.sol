// SPDX-License-Identifier: GPL-3.0
/* solhint-disable one-contract-per-file */

pragma solidity ^0.8.9;

interface IPREApplication {
    function bondOperator(address _stakingProvider, address _operator) external;
}

interface ITBTCApplication {
    function registerOperator(address operator) external;

    function approveAuthorizationDecrease(address stakingProvider) external;
}
