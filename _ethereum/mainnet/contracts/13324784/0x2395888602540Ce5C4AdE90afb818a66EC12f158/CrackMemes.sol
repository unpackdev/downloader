// SPDX-License-Identifier: MIT
pragma solidity ^0.7.2;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";

/**
 * The One and Only Crack Memes ERC-721 Smart Contract
 */

contract CrackMemes is ERC721, ERC721Burnable, Ownable {
    using SafeMath for uint256;

    string public CRACKMEMES_PROVENANCE = "";

    constructor() ERC721("CrackMemes", "CRACK") {}

    // “WE LIKE THE CRACK”
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    // “ETH IS FUCKING ADDICTING”
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    // “WEN CRACK”
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        CRACKMEMES_PROVENANCE = provenanceHash;
    }

    // “PEPE IS DEAD”
    function mintCrackMemes(uint256 numberOfTokens) public onlyOwner {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

}
