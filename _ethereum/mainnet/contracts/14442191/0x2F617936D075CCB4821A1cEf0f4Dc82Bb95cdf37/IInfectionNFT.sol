// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface IInfectionNFT {
    function ownerMinting(address to, uint256 numberOfTokens) external payable;
}
