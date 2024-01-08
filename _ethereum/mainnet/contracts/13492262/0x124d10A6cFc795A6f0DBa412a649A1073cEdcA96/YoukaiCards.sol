// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract YoukaiCards is ERC721, ERC721Enumerable, Ownable {
    string public PROVENANCE;
    bool public saleIsActive = false;
    string private _baseURIextended;
    uint constant MAX_TOKENS = 3000 * 2;
    uint constant NUM_RESERVED_TOKENS = 27 * 2;
    

    constructor() ERC721("YoukaiCards", "YKC") {
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function reserveDeck() public onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < NUM_RESERVED_TOKENS; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }
    
    function reserveOne() public onlyOwner {
        uint supply = totalSupply();
        _safeMint(msg.sender, supply);
        
    }
    
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }
    
    function mint(uint numberOfPacks) public payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfPacks <= 10, "Exceeded max purchase amount");
        require(totalSupply() + (numberOfPacks * 2) <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        require(0.08 ether * numberOfPacks <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfPacks * 2; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}