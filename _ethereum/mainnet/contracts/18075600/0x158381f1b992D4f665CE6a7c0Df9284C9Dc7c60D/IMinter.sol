// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMinter {
    function active_period() external view returns (uint256);

    function _token() external view returns (address);
}
