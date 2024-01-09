// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface ITimeNFT {
    struct NFTTime {
        string note;
    }

    event TimeBankUpdated(address indexed user, address value);
    event TimeUpdated(address indexed user, address value);

    event TokenPriceUpdated(address indexed user, uint256 value);

    event TokenMinted(address indexed user, uint256 indexed tokenId);

    event TokenNoteUpdated(address indexed user, string value);

    event BaseUriUpdated(address indexed user, string value);

    event MaxYearUpdated(address indexed user, uint256 value);

    //function claim(uint256 day, uint256 month, uint256 year, string memory note) external;

    //function changeNote(uint256 day, uint256 month, uint256 year, string memory note) external;

}