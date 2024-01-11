// SPDX-License-Identifier: GPL-3.0

//                 _                        _                   _          
//   _ __ ___   __| |  __ _ _ __   ___  ___| |_ _ __ ___  _ __ | |__   ___ 
//  | '_ ` _ \ / _` | / _` | '_ \ / _ \/ __| __| '__/ _ \| '_ \| '_ \ / _ \
//  | | | | | | (_| || (_| | |_) | (_) \__ \ |_| | | (_) | |_) | | | |  __/
//  |_| |_| |_|\__,_(_)__,_| .__/ \___/|___/\__|_|  \___/| .__/|_| |_|\___|
//                         |_|                           |_|               

/**
 * @title Bubble Friends Forever - BFF
 * @notice Artist mdapostrophe.eth https://twitter.com/md_apostrophe 
 * @author tmtlab.eth https://twitter.com/tmtlabs & tanujd.eth https://twitter.com/tanujdamani
 * Description: We all need a bubbly friend in our lives. A lively spirit who is full of joy and can always cheer us up.
**/

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract BubbleFriendsForever is ERC721A, Ownable {
    string public baseURI;
    string public contractURI;

    constructor(string memory _baseURI, string memory _contractURI) ERC721A("Bubble Friends Forever", "BFF") {
        baseURI = _baseURI;
        contractURI = _contractURI;
    }

    /// @notice set the metadata of the collection
    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    /// @notice update the base URI of the collection
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    // Override ERC721A tokenURI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }

    // Override ERC721A to start token from 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @notice Mint NFTs for the collection
    function artistMint(uint256 _qty) public onlyOwner {
        _mint(owner(), _qty);
    }

    /// @notice withdraw all balance from the contract
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }
}
