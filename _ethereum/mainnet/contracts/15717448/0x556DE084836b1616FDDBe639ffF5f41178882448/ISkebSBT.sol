// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface ISkebSBT {
    function changeBaseURI(string memory newURI) external;

    function safeMint(address to) external;

    function batchSafeMint(address[] memory toAddresses) external;
}
