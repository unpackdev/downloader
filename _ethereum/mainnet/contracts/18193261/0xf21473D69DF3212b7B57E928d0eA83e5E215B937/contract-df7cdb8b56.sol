// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Counters.sol";
import "./Base64.sol";

contract RecipeForChaos is ERC721 {
    bool private initialized;

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    address private constant GROUP_ADDRESS = 0xa4Fb56FaCeD8D08248d7d9c60C5257A924eCad15;

    constructor() ERC721("RecipeForChaos", "RC") {
        // mint token zero to group wallet
        _mint(GROUP_ADDRESS, 0);
        _mint(address(0x5CE191eF43a87450faEa24C3487433E2bb0fEE1b), 1);
        _mint(address(0x581420a87f00b4B552a3A261e21878Ea5c27e97f), 2);
        // set initialized to true
        initialized = true;
    }

    function reallyReallySafeMint(address to) public {
        require(
            msg.sender == GROUP_ADDRESS,
            "Only the group wallet can mint."
        );
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        // unsafe mint
        _mint(to, tokenId);
    }

    function tokenURI(uint256 /*id*/) public pure override returns (string memory) {
        return _buildTokenURI();
    }
    
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (tokenId == 0 && initialized) {
            revert("Token ID 0 can't be transferred.");
        }
        super._transfer(from, to, tokenId);
    }

    // Constructs the encoded svg string to be returned by tokenURI()
    function _buildTokenURI() internal pure returns (string memory) {
        bytes memory image = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<?xml version="1.0" encoding="UTF-8"?>',
                        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" viewBox="0 0 400 400" preserveAspectRatio="xMidYMid meet">',
                        '<style type="text/css"><![CDATA[text { font-family: monospace;} .h1 {font-size: 40px; font-weight: 600;}]]></style>',
                        '<rect width="400" height="400" fill="#ffffff" />',
                        '<text class="h1" x="80" y="180">One wallet.</text>',
                        '<text class="h1" x="80" y="240">No rules.</text>',
                        '</svg>'
                    )
                )
            )
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Recipe for Chaos", "image":"',
                                image,
                                '", "description": "Simple instructions for the group wallet. The image is on-chain just like you."}'
                            )
                        )
                    )
                )
            );
    } 
}

