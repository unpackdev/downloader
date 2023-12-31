// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface INieuxCollective {
    function airdropOne(address to) external;

    function renounceOwnership() external;

    function setBaseURI(string memory uri) external;

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external payable;

    function transferOwnership(address newOwner) external;

    function withdraw() external payable;
}
