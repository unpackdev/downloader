// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct TokenData {
    uint256[] royalties;
    address[] creators;
    uint256 quantity;
    string uri;
    string name;
}

interface NiftySouqINftV1 {
    function getTokenData(uint256 tokenId)
        external
        view
        returns (TokenData memory);
}
