// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPrivatePresale {
    function getAllocationFraudInDubai(address _user) external view returns (uint256);
    function getClaimOpenDate() external view returns (uint256);
    function getClaimOpenEpoch() external view returns (uint256);
    function getLockedInDubai() external view returns (uint256);
}