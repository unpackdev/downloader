// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IFlashMintBorrower {
    function doSomething(uint256 amountD2, uint256 fee, bytes calldata data) external;
}
