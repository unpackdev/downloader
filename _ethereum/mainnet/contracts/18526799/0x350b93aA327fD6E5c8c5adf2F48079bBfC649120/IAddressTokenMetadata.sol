// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

interface IAddressTokenMetadata {
    function tokenJSON(uint256 tokenId) external pure returns(string memory);
}
