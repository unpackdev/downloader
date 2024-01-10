// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

interface IIncarnateEcho {
    function mint(address to, uint256 quantity) external;
    function burn(uint256 tokenId) external;
    function addMinter(address minter) external;
    function removeMinter(address minter) external;
    function getTokenBaseUri() view external returns (string memory);
    function setTokenBaseUri(string memory tokenBaseUri) external;
}