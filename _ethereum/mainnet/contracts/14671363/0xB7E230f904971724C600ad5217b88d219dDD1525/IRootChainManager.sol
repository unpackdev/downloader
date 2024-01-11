//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IRootChainManager {
    function exit(bytes calldata inputData) external;
}
