// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IPool {
    function addBuyer(address buyerAddress, uint256 amount, bool isOdd) external;

    function updateBuyer(address buyerAddress, uint256 amount, bool isOdd) external;

    function deleteBuyer(address buyerAddress) external;
}
