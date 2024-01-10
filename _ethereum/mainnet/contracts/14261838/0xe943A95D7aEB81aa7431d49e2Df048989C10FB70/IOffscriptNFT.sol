// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IERC721.sol";

interface IOffscriptNFT is IERC721 {
    struct Metadata {
        uint8 discount;
        string name;
    }

    function getMetadata(uint256 tokenId)
        external
        view
        returns (uint8 discount, string memory name);
}
