// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

interface ISmartAlpha {
    function epoch() external view returns (uint256);
    function getCurrentEpoch() external view returns (uint256);
    function advanceEpoch() external;
}
