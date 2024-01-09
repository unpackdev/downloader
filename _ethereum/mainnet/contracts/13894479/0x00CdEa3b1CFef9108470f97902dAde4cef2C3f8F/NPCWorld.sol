// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

 /*$$  /$$ /$$$$$$$   /$$$$$$        /$$      /$$  /$$$$$$  /$$$$$$$  /$$       /$$$$$$$
| $$$ | $$| $$__  $$ /$$__  $$      | $$  /$ | $$ /$$__  $$| $$__  $$| $$      | $$__  $$
| $$$$| $$| $$  \ $$| $$  \__/      | $$ /$$$| $$| $$  \ $$| $$  \ $$| $$      | $$  \ $$
| $$ $$ $$| $$$$$$$/| $$            | $$/$$ $$ $$| $$  | $$| $$$$$$$/| $$      | $$  | $$
| $$  $$$$| $$____/ | $$            | $$$$_  $$$$| $$  | $$| $$__  $$| $$      | $$  | $$
| $$\  $$$| $$      | $$    $$      | $$$/ \  $$$| $$  | $$| $$  \ $$| $$      | $$  | $$
| $$ \  $$| $$      |  $$$$$$/      | $$/   \  $$|  $$$$$$/| $$  | $$| $$$$$$$$| $$$$$$$/
|__/  \__/|__/       \______/       |__/     \__/ \______/ |__/  |__/|________/|______*/

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";

contract NPCWorld is ERC721Enumerable, Ownable {

    uint256 public MAX_SUPPLY = 48;
    uint256 private _tokenId = 1;
    string private _baseTokenURI;

    constructor(string memory baseTokenURI) ERC721("NPCWorld", "NPCWTF") {
         _baseTokenURI = baseTokenURI;
    }

    function mint() public onlyOwner {
        require(_tokenId < MAX_SUPPLY, "Exceeds maximum supply");

        _safeMint(msg.sender, _tokenId);

        _tokenId = _tokenId + 1;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "contract"));
    }

    function minted() public view returns (uint256) {
        return _tokenId - 1;
    }

    function withdraw() public payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}
