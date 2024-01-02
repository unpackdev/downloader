// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface ITokenFactory {
    function create(
        string calldata,
        string calldata,
        string calldata,
        address,
        bytes calldata
    )
        external
        returns (address);
    function setTokenDeployerAddress(address) external;
}
