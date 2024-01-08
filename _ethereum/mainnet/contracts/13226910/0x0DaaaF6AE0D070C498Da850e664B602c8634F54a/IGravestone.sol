// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IGravestone {
    event Place(uint256 indexed tokenId_, uint128 indexed location_);
    event Remove(uint256 indexed tokenId_, uint128 indexed location_);
    event UpdateTokenURI(uint256 indexed tokenId_, string tokenURI_);

    function mint(
        address to_,
        string calldata name_,
        uint24[2] calldata birthDeathYear_,
        uint8[2] calldata birthDeathMonth_,
        uint16[2] calldata birthDeathOrdinalDay_,
        uint256 adornmentId_,
        string calldata epitaph_,
        uint32[2] calldata latitudeLongitude_,
        string calldata tokenURI_
    ) external returns (uint256);

    function burn(uint256 tokenId_) external;

    function updateTokenURI(uint256 tokenId_, string calldata tokenURI_)
        external;

    function gravestone(uint256 tokenId_)
        external
        view
        returns (
            string memory name_,
            uint24 birthYear_,
            uint8 birthMonth_,
            uint16 birthOrdinalDay_,
            uint24 deathYear_,
            uint8 deathMonth_,
            uint16 deathOrdinalDay_,
            uint256 adornmentId_,
            string memory epitaph_,
            uint32 latitude_,
            uint32 longitude_,
            string memory tokenURI_
        );

    function gravestoneAdornment(uint256 tokenId_)
        external
        view
        returns (bytes32[] memory);
}
