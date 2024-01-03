// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.6.0;

interface RandomnessInterface {
    function randomNumbers(address, uint32) external view returns (uint);
    function getRandom(uint256, uint32) external;
}