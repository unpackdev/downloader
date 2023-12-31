// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Counters.sol";
import "./Base64.sol";

contract RecipeForChaosFixed is ERC721 {
    bool private initialized;

    uint private _nextTokenId = 5;

    address private constant GROUP_ADDRESS = 0xa4Fb56FaCeD8D08248d7d9c60C5257A924eCad15;

    constructor() ERC721("RecipeForChaosFixed", "RCF") {
        // mint token zero to group wallet
        _mint(GROUP_ADDRESS, 0);
        _mint(address(0x5CE191eF43a87450faEa24C3487433E2bb0fEE1b), 1);
        _mint(address(0x581420a87f00b4B552a3A261e21878Ea5c27e97f), 2);
        _mint(address(0x735854c506CcEb0b95C949d1acB705b31136d487), 3);
        _mint(address(0xD91375206d6f1773459762cBeaC0966190573069), 4);
        // set initialized to true
        initialized = true;
    }

    function reallyReallySafeMint(address to) public {
        require(
            msg.sender == GROUP_ADDRESS,
            "Only the group wallet can mint."
        );
        // unsafe mint
        _mint(to, _nextTokenId);

        unchecked {
            _nextTokenId++;
        }
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
                        '<style type="text/css"><![CDATA[text { font-family: monospace; fill: #7e8ffa;} .h1 {font-size: 30px; font-weight: 600;}]]></style>',
                        '<rect width="400" height="400" fill="#2f2f2f" />',
                        '<text class="h1" x="40" y="190">One seed phrase.</text>',
                        '<text class="h1" x="40" y="230">No rules.</text>',
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
                                '", "description": "Simple instructions for the group wallet. The image is on-chain just like you. diid wuz here."}'
                            )
                        )
                    )
                )
            );
    } 
}