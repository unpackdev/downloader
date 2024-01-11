// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "IERC721.sol";
import "IERC1155.sol";

library TokenLibrary {

    enum TypeOfToken {
        ERC721,
        ERC1155
    }

    struct TokenValue {
        address token;
        uint256 tokenId;
        uint256 tokenValue;
    }

    function typeOfToken(uint256 tokenValue) internal pure returns(TypeOfToken) {
        if (tokenValue == 0){
            return TypeOfToken.ERC721;
        }
        else {
            return TypeOfToken.ERC1155;
        }
    }

    function transferFrom(TokenValue storage token, address from, address to) internal {

        if (typeOfToken(token.tokenValue) == TypeOfToken.ERC721) {
            IERC721(token.token).safeTransferFrom(from, to, token.tokenId);
        } 
        else {
            IERC1155(token.token).safeTransferFrom(from, to, token.tokenId, token.tokenValue, "");
        }

    }
}