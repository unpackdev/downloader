// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ITokenPool {
    function lockOrBurn(uint256 amount) external;
    function releaseOrMint(address receiver, uint256 amount) external;
}
