// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract AsciiFrensNFT is Ownable, ERC721A, ReentrancyGuard {

    uint public immutable MAX_SUPPLY = 100000;
    uint16 public immutable MAX_TEAM_SUPPLY = 250;
    uint16 public teamCounter = 0;
    uint8 public saleStage; // 0: PAUSED | 1: SALE | 2: SOLDOUT
    string public baseTokenURI;

    constructor() ERC721A('Ascii Frens', '0xAF', 20, 100000) {
        saleStage = 0;
    }

    // UPDATE SALESTAGE

    function setSaleStage(uint8 _saleStage) external onlyOwner {
        require(saleStage != 2, "Cannot update if already reached soldout stage.");
        saleStage = _saleStage;
    }

    // PUBLIC MINT 

    function publicMint(uint _quantity) external nonReentrant {
        require(saleStage == 1, "Public sale is not active.");
        require(balanceOf(msg.sender) + _quantity <= 3, "Would reach the max mint amount per holder.");
        require(totalSupply() + _quantity + (MAX_TEAM_SUPPLY-teamCounter) < MAX_SUPPLY, "Mint would exceed max supply.");

        _safeMint(msg.sender, _quantity);
        if (totalSupply() + (MAX_TEAM_SUPPLY-teamCounter) == MAX_SUPPLY) {
            saleStage = 2;
        }
    }

    // TEAM MINT

    function teamMint(address _to, uint16 quantity) external onlyOwner {
        require(teamCounter + quantity <= MAX_TEAM_SUPPLY, "Wouldl exceed max team supply.");
        _safeMint(_to, quantity);
        teamCounter += quantity;
    }
    
    // METADATA URI

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenUri(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexisting token");
        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, Strings.toString(tokenId), ".json")) : "https://bafybeiabjl4zvtctltv7vhrzjdo73lgxp4ef3x33hgqkvgcnbe3ehkibfm.ipfs.dweb.link/metadata.json";
    }
}