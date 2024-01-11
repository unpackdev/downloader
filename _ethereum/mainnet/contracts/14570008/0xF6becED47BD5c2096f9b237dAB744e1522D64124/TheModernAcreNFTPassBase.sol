// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TheModernAcreNFTPassBase.sol";

contract TheModernAcreNFTPassBase {
    uint256 public TOTAL_PUBLIC_SUPPLY;
    uint256 public TOTAL_RESERVED_SUPPLY;
    uint256 public TOTAL_MENTOR_SUPPLY;
    uint256 public TOTAL_MENTEE_SUPPLY;

    uint256 public amountMintedTotal;
    uint256 public amountMintedPublic;
    uint256 public amountMintedReserved;
    uint256 public amountMintedMentor;
    uint256 public amountMintedMentee;

    uint256 funds;

    uint256 public PRICE;
    uint256[] public mentorTokenIds;
    mapping(uint256 => uint256) tokenIdToImage;
    string[] images;
    string public BASE_URI;
    bool public presale;
}
