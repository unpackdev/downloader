// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract SadFrogs is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    string private _baseURIPrefix;

    uint private constant maxTokensPerTransaction = 30;
    uint256 private tokenPrice = 50000000000000000; //0.05 ETH
    uint256 private constant nftsNumber = 7000;
    uint256 private constant nftsPublicNumber = 6950;
    
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Sad Frogs District", "SFD") {
        _tokenIdCounter.increment();
    }
    
    function setPrice(uint256 newPrice) public onlyOwner {
        tokenPrice = newPrice;
    }

    function getTokenPrice() public view returns (uint256) {
        return tokenPrice;
    }

    function setBaseURI(string memory baseURIPrefix) public onlyOwner {
        _baseURIPrefix = baseURIPrefix;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }
    
    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }
    
    function directMint(address to, uint256 tokenId) public onlyOwner {
        require(tokenId > nftsPublicNumber, "Tokens number to mint must exceed number of public tokens");
        _safeMint(to, tokenId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    function buyFrogs(uint tokensNumber) whenNotPaused public payable {
        require(tokensNumber > 0, "Wrong amount");
        require(tokensNumber <= maxTokensPerTransaction, "Max tokens per transaction number exceeded");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber, "Tokens number to mint exceeds number of public tokens");
        require(tokenPrice.mul(tokensNumber) <= msg.value, "Ether value sent is too low");

        for(uint i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }
}