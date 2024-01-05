// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IEthGateway {
    function transferToSmartChain(uint256 amount) external;
}