// SPDX-License-Identifier: GPL

pragma solidity ^0.8.6;

interface ITodayToken {
    event TokenMinted(address indexed to, uint256 indexed tokenId);

    event TokenBurned(uint256 indexed tokenId);

    event MinterUpdated(address nweMinter);

    function mint(string memory tokenDate) external returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function burn(uint256 tokenId) external;
}
