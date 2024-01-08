// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface IVFRBuffer {
    function target() external view returns (uint256);

    function request(uint256 _amount) external;
}
