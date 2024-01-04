// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IJug {
    function ilks(bytes32 ilk) external view returns (uint256, uint256);

    function base() external view returns (uint256);
}
