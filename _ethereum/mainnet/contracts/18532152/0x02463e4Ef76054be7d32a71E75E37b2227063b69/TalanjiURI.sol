// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// using BokkyPooBahsDateTimeContract.sol for datatime
interface IDateTime {
    function getMonth(uint256 timestamp) external view returns (uint256);
    function getDay(uint256 timestamp) external view returns (uint256);
}

// Implementation of a custom tokenURI
interface ITokenURICustom {
    function constructTokenURI(uint256 tokenId) external view returns (string memory);
}

/// @title Talanji Dynamic URI
/// @author Mauro
/// @notice Computes the URI of Dark Talanji dynamically, given the current timestamp
contract TalanjiURI {
    // OG Talanji Minted: Dec-29-2020 12:00:19 AM +UTC

    uint256 public constant MINT_DAY = 29;
    uint256 public constant MINT_MONTH = 12;

    IDateTime public immutable dateTime;

    constructor() {
        dateTime = IDateTime(0x23d23d8F243e57d0b924bff3A3191078Af325101);
    }

    function constructTokenURI(uint256 tokenId) public view returns (string memory tokenURI) {
        require(tokenId == 4, "tokenId not valid");

        uint256 day = dateTime.getDay(block.timestamp);
        uint256 month = dateTime.getMonth(block.timestamp);

        if (day == 29 && month == 12) {
            tokenURI = "https://ipfs.pixura.io/ipfs/QmescFbLicu6B7WGYfhMDjPuxRzH5tfSJ2aTwCHDWEL6Uj/metadata.json"; // OG TALANJI SuperRare
        } else {
            tokenURI = "ipfs://QmeSj4jJd94zp9TfGJFHRQM5kti4kF4C5HwvtYSKkHMLHw"; // Talanji 2023
        }
    }
}
