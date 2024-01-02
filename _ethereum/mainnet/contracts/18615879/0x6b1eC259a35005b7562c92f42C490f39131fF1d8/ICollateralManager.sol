// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface ICollateralManager {
    function getEscrow(uint256 _bidId) external view returns (address);
}
