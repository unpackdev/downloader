// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library errors {
    string constant public NOT_AUTHORIZED = "11";
    string constant public INVALID_ADDRESS = "12";

    string constant public NOT_SINGLE_NFT = "21";
    string constant public FRAME_ID_MISSING = "22";

    string constant public ZERO_ADDRESS = "31";
    string constant public NOT_VALID_NFT = "32";
    string constant public NOT_OWNER_OR_OPERATOR = "33";
    string constant public NOT_OWNER_APPROVED_OR_OPERATOR = "34";
    string constant public NOT_ABLE_TO_RECEIVE_NFT = "35";
    string constant public NFT_ALREADY_EXISTS = "36";
    string constant public NOT_OWNER = "37";
    string constant public IS_OWNER = "38";

    string constant public FRAME_NOT_EMPTY = "41";
    string constant public FRAME_EMPTY = "42";

    string constant public NOT_VALID_MODEL = "51";
    string constant public NOT_IN_STOCK = "52";
    string constant public CHECK_NOT_VALID = "53";
    string constant public INVALID_SIGNATURE = "54";

    string constant public MISMATCHING_LENGTHS = "61";
}
