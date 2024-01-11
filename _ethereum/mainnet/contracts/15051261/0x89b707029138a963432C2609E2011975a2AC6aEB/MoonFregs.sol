// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract MoonFregs is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string private _baseURIPrefix;
    uint256 private tokenPrice = 10000000000000;// 0.001 ETH
    uint256 private constant hardcapAmount = 8240;
    uint256 private constant totalAmount = 8000;
    uint256 private constant freeAmount = 5000;
    uint256 private constant perWallet = 3;
    mapping(address => uint) public claimed;
    
    constructor() ERC721("Moon Fregs", "MoonFregs") {
        _tokenIdCounter.increment();
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setPrice(uint newPrice) public onlyOwner {
        tokenPrice = newPrice;
    }

    function setBaseURI(string memory baseURIPrefix) public onlyOwner {
        _baseURIPrefix = baseURIPrefix;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function freeMint(uint tokensNumber) public {
        require(tokensNumber > 0, "Wrong amount");
        require(tokensNumber + claimed[msg.sender] <= perWallet, "Wrong amount");
        require(_tokenIdCounter.current() + tokensNumber <= freeAmount, "Free mint finished");

        for(uint i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            claimed[msg.sender] += 1;
            _tokenIdCounter.increment();
        }
    }

    function buyFregs(uint tokensNumber) public payable {
        require(tokensNumber > 0, "Wrong amount");
        require(tokensNumber + claimed[msg.sender] <= perWallet, "Wrong amount");
        require(_tokenIdCounter.current() + tokensNumber <= totalAmount, "Sale finished");
        require(tokenPrice * tokensNumber <= msg.value, "Need more ETH");

        for(uint i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            claimed[msg.sender] += 1;
            _tokenIdCounter.increment();
        }
    }

    function creatorsFregs(uint tokensNumber) public onlyOwner {
        require(_tokenIdCounter.current() + tokensNumber <= hardcapAmount, "No more fregs");

        for(uint i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

}
