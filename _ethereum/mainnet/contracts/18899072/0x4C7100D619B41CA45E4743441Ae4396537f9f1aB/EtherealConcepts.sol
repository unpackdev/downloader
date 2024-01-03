// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract EtherealConcepts is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    // Counter for token
    uint256 private _tokenIdCounter = 0;

    // Founder address
    address private _founder;

    // Mapping NFT ID to its CID in IPFS
    mapping(uint256 => string) private _tokenCIDs;

    // Prefix and postfix for NFT URI
    string private _uri_prefix = "ipfs://";
    string private _uri_postfix = "";

    constructor() ERC721("Ethereal Concepts", "Econ") {
        _founder = msg.sender;
    }

    modifier onlyFounder() {
        require(msg.sender == _founder, "Ethereal Concepts: caller is not the founder");
        _;
    }

    // Getting the full URI for the NFT
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Ethereal Concepts: URI query for nonexistent token");
        string memory cid = _tokenCIDs[tokenId];
        return string(abi.encodePacked(_uri_prefix, cid, _uri_postfix));
    }

    // Creating one NFT with the specified CID for the founder
    function createToken(string memory ipfsCID) public onlyFounder {
        _safeMint(_founder, _tokenIdCounter);
        _tokenCIDs[_tokenIdCounter] = ipfsCID;
        _tokenIdCounter = _tokenIdCounter.add(1);
    }

    // Creating multiple tokens with specified CIDs for the founder
    function createTokens(string[] memory ipfsCIDs) public onlyFounder {
        for (uint256 i = 0; i < ipfsCIDs.length; i++) {
            createToken(ipfsCIDs[i]);
        }
    }

    // Setting a new CID for the founder's NFT
    function setTokenCID(uint256 tokenId, string memory ipfsCID) public {
        if (msg.sender != _founder || ownerOf(tokenId) != _founder) {
            revert("Ethereal Concepts: Not the founder or not the owner of the token");
        }

        _tokenCIDs[tokenId] = ipfsCID;
    }

    // Destruction of the founder's NFT by the founder themself
    function burnToken(uint256 tokenId) public {
        if (msg.sender != _founder || ownerOf(tokenId) != _founder) {
            revert("Ethereal Concepts: Not the founder or not the owner of the token");
        }

        _burn(tokenId);
        _tokenCIDs[tokenId] = "";
    }

    // Setting a new prefix and suffix for URI by the founder
    function setUriPrefixPostfix(string memory newPrefix, string memory newPostfix) public onlyFounder {
        _uri_prefix = newPrefix;
        _uri_postfix = newPostfix;
    }
}
