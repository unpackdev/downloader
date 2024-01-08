// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomnessProvider {
    function newRandomnessRequest() external returns (bytes32);

    function updateFee(uint256) external;

    function rescueLINK(address to, uint256 amount) external;
}
