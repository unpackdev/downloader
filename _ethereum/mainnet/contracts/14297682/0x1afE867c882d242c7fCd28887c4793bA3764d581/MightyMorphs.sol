// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Strings.sol";

import "./Base64.sol";

contract MightyMorphs is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public constant PRICE = 0.1 ether;

    event NewMightyMorphMinted(address sender, uint256 tokenId);

    function mint() public payable {
        uint256 newItemId = _tokenIds.current();

        require(msg.value >= PRICE, "Not enough ether to purchase NFT.");

        string memory payload = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Mighty Morph #',
                        Strings.toString(newItemId + 1),
                        '", "description": "',
                        "It's Morphin' Time!",
                        '", "image": "https://api.mightymorphs.com/image/',
                        Strings.toHexString(uint256(uint160(msg.sender)), 20),
                        '"}'
                    )
                )
            )
        );

        string memory tokenUri = string(
            abi.encodePacked("data:application/json;base64,", payload)
        );

        _safeMint(msg.sender, newItemId + 1);
        _setTokenURI(newItemId + 1, tokenUri);

        _tokenIds.increment();
        emit NewMightyMorphMinted(msg.sender, newItemId + 1);
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    constructor() ERC721("MightyMorphs", "MORPHS") Ownable() {}
}
