// SPDX-License-Identifier: MIT
//
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";


contract RandomGaussians is ERC721, ERC721Enumerable, Ownable {
    bool private _active;
    string private _baseURIextended;
    uint256 private _activeTime;
    uint constant MAX_TOKENS = 10000;
    uint constant FREE_MINTS = 30;

    constructor() ERC721("RandomGaussians", "RNG") {
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }
    
    function activate() external onlyOwner {
        require(!_active, "Already active");
        _activeTime = block.timestamp;
        _active = true;
    }
    
    function deactivate() external onlyOwner {
        require(_active, "Already inactive");
        delete _activeTime;
        _active = false;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function mintFree() public payable {
        require(_active, "Inactive");
        require(totalSupply() + 1 <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        require(totalSupply() <= FREE_MINTS, "No more free mints available!");
        require(balanceOf(msg.sender) < 1, "No freee mints, you already own a token");
        uint mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex);
    }

    function mint(uint numTokens) public payable {
        require(_active, "Inactive");
        require(numTokens <= 30, "Exceeded max purchase amount");
        require(totalSupply() + numTokens <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        require(0.05 ether * numTokens <= msg.value, "Ether value sent is not correct");
        for(uint i = 0; i < numTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
    
    function withdraw(address payable recipient, uint256 amount) public onlyOwner {
		recipient.transfer(amount);
    }

    
}