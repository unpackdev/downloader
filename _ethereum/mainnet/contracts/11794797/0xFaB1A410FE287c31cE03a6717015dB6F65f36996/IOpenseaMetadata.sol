// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

interface IOpenSeaMetadata {
    function contractURI() external view returns (string memory);
}
