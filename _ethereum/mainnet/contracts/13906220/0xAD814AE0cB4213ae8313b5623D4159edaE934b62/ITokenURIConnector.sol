// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ITokenURIConnector {
    function tokenURI() external view returns (string memory);
}
