// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./base64.sol";

contract ChainArt is ERC721URIStorage, Ownable {
    uint256 public tokenCounter;
    uint256 public constant mintPrice = 1 ether;
    address public constant feeAddress = 0xFB2a31B1109599cf3990Bf50eC9fF0b85A4eCC73;

    event CreatedChainArtNFT(uint256 indexed tokenId);

    constructor() ERC721("Chain Art", "CHAIN")
    {
        tokenCounter = 0;
    }

    function createFromBase64(string memory imageData) public payable {

        require(msg.value == mintPrice, "Invalid mint price");

        _safeMint(msg.sender, tokenCounter);
        _setTokenURI(tokenCounter, formatTokenURI(imageData));
        tokenCounter = tokenCounter + 1;

        payable(feeAddress).transfer(mintPrice);

        emit CreatedChainArtNFT(tokenCounter);
    }


    function formatTokenURI(string memory imageURI) public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            "Chain Art",
                            '", "image":"', imageURI, '"}'
                        )
                    )
                )
            )
        );
    }
}