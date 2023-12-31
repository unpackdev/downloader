// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IWasabiOption {
    function mint(address, address) external returns (uint256);

    function burn(uint256) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);
}
