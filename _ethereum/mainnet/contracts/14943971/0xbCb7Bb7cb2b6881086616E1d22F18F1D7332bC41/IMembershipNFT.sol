//SPDX-License-Identifier: Unlicense
// Creator: Dai
pragma solidity ^0.8.4;

interface IMembershipNFT {
    event Mint(
        address indexed operator,
        address indexed to,
        uint256 quantity,
        uint256 tierIndex
    );
    event Burn(address indexed operator, uint256 tokenID);
    event UpdateMetadataImage(string[]);
    event UpdateMetadataExternalUrl(string[]);
    event UpdateMetadataAnimationUrl(string[]);
    event SetupPool(address indexed operator, address pool);
    event Locked(address indexed operator, bool locked);
    event MintToPool(address indexed operator);

    function tierSupply(uint8) external view returns (uint256);

    function tierName(uint8) external view returns (string memory);

    function tierCount(uint8) external view returns (uint256);

    function tierStartId(uint8) external view returns (uint256);

    function tierEndId(uint8) external view returns (uint256);

    function numberTiers() external view returns (uint256);
}
