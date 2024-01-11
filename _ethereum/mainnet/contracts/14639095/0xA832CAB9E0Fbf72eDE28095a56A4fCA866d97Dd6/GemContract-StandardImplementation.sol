// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";

contract ExtraordinaryCrystal is ERC721, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint alphaToken;

    constructor() ERC721("The Extraordinary Crystal", "CRYSTALS") {
        safeMint(msg.sender);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        if (tokenId == alphaToken && from != owner()) {
            require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
            require(to != address(0), "ERC721: transfer to the zero address");

            safeMint(to);
        } else {
            super._transfer(from, to, tokenId);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId));

        string memory name = "Ordinary Crystal";
        string memory imageUrl;
        string memory animUrl;
        string memory alphaStatus = "False";
        string memory descPrefix = "The Extraordinary Crystal has been sold to the highest bidder - they now control the collection.";
        if (ownerOf(alphaToken) == owner()) {
            descPrefix = "The Extraordinary Crystal will be sold to the highest bidder - they will control the collection.";
        }

        if (alphaToken == tokenId) {
            name = "Extraordinary Crystal";
            alphaStatus = "True";
            imageUrl = "https://gateway.pinata.cloud/ipfs/QmNTuyMThb76eKZDFUGDn4ZmfaUtLTccTfmhR32dnxfa4W";
            animUrl = "https://gateway.pinata.cloud/ipfs/QmQvSfXc2hLPrnoNGjbR3BWEfaZ7XVYMmt6Dhj2JRq3PLB";
        } else {
            uint c = tokenId % 5;
            if (c == 0) {
                imageUrl = "https://gateway.pinata.cloud/ipfs/QmYhDdz9qsea1sZhj1nV6WGZPuKyJjdnyqPViKNCFX3mAE";
                animUrl = "https://gateway.pinata.cloud/ipfs/QmVYpN2ov7RjjCvCpuMZFyym2hEXuv4QA3gDsecdNLKeAM";
            } else if (c == 1) {
                imageUrl = "https://gateway.pinata.cloud/ipfs/QmWXSKRJBnRLk56FqTDyMiiewwya4yv7qMW5agUe1obAZN";
                animUrl = "https://gateway.pinata.cloud/ipfs/QmUjVWZJrh7W3utTsNQpdEkxTW7W9tYF9Ns3afsCh8Uucp";
            } else if (c == 2) {
                imageUrl = "https://gateway.pinata.cloud/ipfs/QmP8epA6o1XxboKxxQPbndtZx57ikgkSakyunfegsbzBnB";
                animUrl = "https://gateway.pinata.cloud/ipfs/QmZjPfqZTcYxFVhmWrMprhWDMZFjkGmaTm4hqbNQM7kvbS";
            } else if (c == 3) {
                imageUrl = "https://gateway.pinata.cloud/ipfs/Qmeov2DYzcrcUipnkHvkgjGxsjf1k9bMrng8idw85Pvjx5";
                animUrl = "https://gateway.pinata.cloud/ipfs/QmSdqS5a1G3grV9ZYbyerp2LNjQuUSPWEpExVBXBEpjhZ2";
            } else if (c == 4) {
                imageUrl = "https://gateway.pinata.cloud/ipfs/QmVuxmAFjp8WaAPgAMavWMEsdLH6arWYhEg4XAaGMT5AqS";
                animUrl = "https://gateway.pinata.cloud/ipfs/QmT4w2thVRKnnYLyMPKBGqoNzt2mtaYapamAmfECD6VnGA";
            }
        }

        string memory json = string(
                abi.encodePacked( 
                    '{"name": "', name, '",',
                    '"description": "', descPrefix, '\\n\\nThe Extraordinary Crystal can never leave the winner\'s wallet - ',
                    'if they sell or transfer the Extraordinary Crystal, a new Ordinary Crystal will instead be minted to the receiving wallet.\\n\\n',
                    'In this way, the collector of the Extraordinary Crystal becomes the architect of the collection - will they choose scarcity or abundance?\\n\\n',
                    'The Extraordinary Crystals collection is a collaboration from @makeitrad1 and @ktrbychain",',
                    '"created_by": "makeitrad & ktrby",',
                    '"image": "', imageUrl, '",'
                    '"image_url": "', imageUrl, '",',
                    '"animation": "', animUrl, '",',
                    '"animation_url": "', animUrl, '",',
                    '"attributes":[',
                    '{"trait_type":"Alpha","value":"', alphaStatus, '"}',
                    "]}"
                )
            );

        return string(abi.encodePacked('data:application/json;utf8,', json));
    }
}