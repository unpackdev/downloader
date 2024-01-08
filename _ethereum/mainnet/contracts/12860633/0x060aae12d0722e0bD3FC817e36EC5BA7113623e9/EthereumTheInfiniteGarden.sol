// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: pplpleasr
/// @author: manifold.xyz

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";

import "./ERC165Checker.sol";


/**
 * Ethereum - The Infinite Garden
 */
contract EthereumTheInfiniteGarden is AdminControl {

    address private immutable _creator;
    bool private _dropped;

    constructor(address creator) {
        _creator = creator;
    }

    /**
     * @dev Activate the contract and mint the tokens
     */
    function drop(address eg, address ceg, address cg, address[] memory it) public adminRequired {
        require(!_dropped, "Already dropped");
        require(it.length == 17, "17 Thanks required");

        _dropped = true;
        string[20] memory hashes = [
            "_av6slQBBGGJr4HKdTVCraFEgQyx5UJ6-0qjx20Bxw0",
            "J6xki5RkOiKbLEgRWylmDJN4s8b70ElrL93KIP8sV_8",
            "vwAAxmqoHauKqVz4wh4J9CkdefT1Wh_v7Uf2575Yn0Q",
            "afIvRsQELjNHcVIcZSd2dknWm-YIMsYvAyPPOtYsyCY",
            "EvvDE1rOJEPKofRBtB4xos4WPEwkqy7lBL26lvDgDsQ",
            "9QrrpRayCQxN9iuZ8VXDApPCraAjGA_Ju6LOkAItFJY",
            "eGP8rZi5HhvCwGgZlq-kXtclnFE2kK7ncxy_TuXVN0U",
            "1sddVZBOmskUei7ERe8InzF2cjBkpS6D9YUT4Hx3E0w",
            "MKonXITIYDF2KhzJUF1hLjQGtFyTsVW50ByaVWF7Xks",
            "gQ0iaULYqexCIfBKaplENibT3L_tpgRzT_dOOSCG2fQ",
            "bZN2sTwl8C7k2CZCRwyAWvu7MzHLBKKJi4ZTkLAU1cE",
            "Sv2mjHva_ck1VX59VSiYE-C7gC81IhEmX_0TLYe-R38",
            "GJhBhWHew5VlRIQe27Vn-Ew4hKYlsUccq7FWiRHouhE",
            "elP80gvxW3oXqIT0HYTNkCn9CRLlJzHuFz-Nn8CH21M",
            "xUrJeZwGolU6BhzdMo9oFKjRS9fhZBwdqq4qnpjxnDc",
            "4flDytVRPYkF3NBBXi3QKxEIcHv8IwFUDgErInaDgBw",
            "5-8rr_GjYMHTwiAegO2PjR_kPwVWShtxYhOCJNoPxnw",
            "NzHFMmbPWFVRAtU0vMMqjpXtezjOh7iUpJlFyu4GxiA",
            "LYcReYlSDW4dqToNLm0alM2oaxsDijyum4DhmMXsFjU",
            "8-OAba-1k87Zuv-baBjGrhgXbdtvaY5Z-MkohbL-KaI"];

        IERC721CreatorCore(_creator).setTokenURIPrefixExtension('https://arweave.net/');
        IERC721CreatorCore(_creator).mintExtension(eg, hashes[0]);
        IERC721CreatorCore(_creator).mintExtension(ceg, hashes[1]);
        IERC721CreatorCore(_creator).mintExtension(cg, hashes[2]);
        for (uint i = 0; i < it.length; i++) {
            IERC721CreatorCore(_creator).mintExtension(owner(), hashes[i+3]);
        }
    }

    function setBaseTokenURI(string calldata uri) external adminRequired {
        IERC721CreatorCore(_creator).setBaseTokenURIExtension(uri);
    }

    function setBaseTokenURI(string calldata uri, bool identical) external adminRequired {
        IERC721CreatorCore(_creator).setBaseTokenURIExtension(uri, identical);
    }

    function setTokenURI(uint256 tokenId, string calldata uri) external adminRequired {
        IERC721CreatorCore(_creator).setTokenURIExtension(tokenId, uri);
    }

    function setTokenURI(uint256[] calldata tokenIds, string[] calldata uris) external adminRequired {
        IERC721CreatorCore(_creator).setTokenURIExtension(tokenIds, uris);
    }

    function setTokenURIPrefix(string calldata prefix) external adminRequired {
        IERC721CreatorCore(_creator).setTokenURIPrefixExtension(prefix);
    }


}