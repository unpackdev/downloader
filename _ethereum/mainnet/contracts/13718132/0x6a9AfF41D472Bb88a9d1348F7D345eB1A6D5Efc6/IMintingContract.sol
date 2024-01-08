// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMintingContract {

    function mintViaSins(address account, uint256 quantity) external returns (uint256[] memory);
}