//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFT {
    event SetMinter(address minter);
    event Revealed(uint256 curTokenId, uint256 tokenId);
    event BaseURIChanged(string uri);
    event NotRevealedURIChanged(string uri);
    event SetMaxSupply(uint256 amount0, uint256 amount1);

    function getMaxSupply() external returns (uint256 amount);

    function getOverall() external returns (uint256 amount);

    function setMaxSupply(uint256 amount) external;

    function setMinter(address minter) external;

    function mint(address to, uint256 quantity) external;

    function setNotRevealedURI(string memory notRevealedURI) external;

    function setBaseURI(string memory uri) external;

    function reveal(uint256 tokenId) external;
}
