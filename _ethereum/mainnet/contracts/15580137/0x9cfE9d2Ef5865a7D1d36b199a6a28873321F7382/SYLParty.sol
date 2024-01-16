//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./console.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./Strings.sol";

contract SYLParty is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("SYLTARE, Tuner of The Universe", "SYLT") {
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://party-meta-data.syltare.com/";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Party: Invalid token ID");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), "/info.json")) : "";
    }

    // Airdrop NFTs
    function airdropNfts(address[] calldata wAddresses) public onlyOwner {
        for (uint i = 0; i < wAddresses.length; i++) {
            _mintNFTs(wAddresses[i]);
        }
    }

    function _mintNFTs(address wAddress) private {
        uint newTokenID = _tokenIds.current();
        _safeMint(wAddress, newTokenID);
        _tokenIds.increment();
    }
}