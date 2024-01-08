// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IOGCards {
    struct Card {
        bool isGiveaway;
        uint8 borderType;
        uint8 transparencyLevel;
        uint8 maskType;
        uint256 dna;
        uint256 mintTokenId;
        address[] holders;
    }

    function cardDetails(uint256 tokenId) external view returns (Card memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function isOG(address _og) external view returns (bool);

    function holderName(address _holder) external view returns (string memory);

    function ogHolders(uint256 tokenId)
        external
        view
        returns (address[] memory, string[] memory);
}