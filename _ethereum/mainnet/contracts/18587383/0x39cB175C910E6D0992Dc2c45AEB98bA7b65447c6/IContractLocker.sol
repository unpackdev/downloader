// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IContractLocker {
    function ownerHasLocked(address _owner) external view returns (bool);
    function tokenIsLocked(uint256 tokenId) external view returns (bool);
    function operatorIsLocked(address _operator) external view returns (bool);
}