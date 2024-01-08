// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMintingContract {

    function mintViaRoar(address account, uint256 quantity) external returns (uint256[] memory);
}