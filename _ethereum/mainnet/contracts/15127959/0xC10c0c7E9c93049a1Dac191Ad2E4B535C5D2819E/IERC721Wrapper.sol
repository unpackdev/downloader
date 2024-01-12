// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

interface IERC721Wrapper {
    event BaseUriSet(string newBaseUri);
    event TokenUriSet(uint256 indexed tokenId, string uri);
    event ReservedUrisChanged();

    function mintTo(address minter) external;

    function mintTo(address minter, uint256 amount) external;

    function canMint(uint256 amount) external view returns (bool);

    function burn(uint256 tokenId) external;
}