// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./ERC721Base.sol";
import "./ERC721Delegated.sol";
import "./Strings.sol";
import "./base64.sol";
import "./CountersUpgradeable.sol";

contract ThroughTheCornMaze is ERC721Delegated {
    uint256 public currentTokenId = 1;
    uint256 public maxSupply = 1;

    string image;
    string image_url;
    string animation_url;

    constructor(
        address baseFactory
    )
        ERC721Delegated(
            baseFactory,
            "Through the corn maze",
            "CORN",
            ConfigSettings({
                royaltyBps: 0,
                uriBase: "",
                uriExtension: "",
                hasTransferHook: false
            })
        )
    {}

    function mint() public {
        require(currentTokenId < maxSupply + 1);
        _mint(msg.sender, currentTokenId++);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {

        string memory json;

       json = string(
            abi.encodePacked( 
                '{"name": "Through the corn maze",',
                '"description": "A memory of a great day in a corn maze with 2 of my best friends",',
                '"created_by": "Aiden",',
                '"image": "', image, '",'
                '"image_url": "', image_url, '",',
                '"animation_url": "', animation_url, '",',
                '"attributes":[',
                '{"trait_type":"Artist","value":"Aiden"},{"trait_type":"Color","value":"#FAFAFE"}',
                "]}"
            )
        );
        
         return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(json))));
    }

    function setMedia (string memory _image, string memory _image_url, string memory _animation_url) public onlyOwner {
        image = _image;
        image_url = _image_url;
        animation_url = _animation_url;
    }

    function setMaxSupply (uint256 newMaxSupply) public onlyOwner () {
        maxSupply = newMaxSupply;
    }
}