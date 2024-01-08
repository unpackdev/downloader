//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

interface IMetaDataGenerator {
    struct MetaDataParams {
        uint256 tokenId;
        uint256 activeGene;
        uint256 balance;
        address owner;
    }

    struct Attribute {
        uint256 layer;
        uint256 scene;
    }

    struct EncodedData {
        uint8[576] composite;
        uint256[] colorPalette;
        string[] attributes;
    }

    function getSVG(uint256 activeGene, uint256 balance) external view returns (string memory);

    function tokenURI(MetaDataParams memory params) external view returns (string memory);

    function getEncodedData(uint256 activeGene) external view returns (EncodedData memory);

    function ossified() external view returns (bool);
}
