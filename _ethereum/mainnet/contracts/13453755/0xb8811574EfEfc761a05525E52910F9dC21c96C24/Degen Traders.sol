// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract DEGENS is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    string private _baseURIPrefix;

    Counters.Counter private _tokenIdCounter;
    uint private constant maxTokensPerTransaction = 15;
    uint256 private tokenPrice = 50000000000000000; //0.05 ETH
    uint256 private tokenPriceWhite = 30000000000000000; //0.03 ETH

    uint256 private constant nftsNumber = 10100;
    uint256 private constant nftsPublicNumber = 10000;
    uint256 public PROVENANCE;
    
    mapping(address => uint) public whitelist;
    mapping(address => uint) public claimed;
    bool public whitelistSaleActive = false;
    bool public mainSaleActive = false;

  
    constructor() ERC721("DEGENS", "DEG") {
        _tokenIdCounter.increment();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    function setBaseURI(string memory baseURIPrefix) public onlyOwner {
        _baseURIPrefix = baseURIPrefix;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
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
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function setProvenance(string memory rate) public onlyOwner {
        PROVENANCE = random(string(abi.encodePacked('DEGENS', rate))) % 10100;
    }
    
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    
    function flipWhitelistSale() public onlyOwner {
        whitelistSaleActive = !whitelistSaleActive;
    }
    
    function flipMainSale() public onlyOwner {
        mainSaleActive = !mainSaleActive;
    }
    
    function addToWhitelist(address[] memory _address, uint32[] memory _amount)public onlyOwner {
        for (uint i = 0; i < _address.length; i++) {
            whitelist[_address[i]] = _amount[i];
        }
    }
        
    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }
    
    function buyWhite(uint tokensNumber) public payable {
        require(tokensNumber > 0, "Wrong amount");
        //require(tokensNumber <= maxTokensPerTransaction, "Max tokens per transaction number exceeded");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber, "Tokens number to mint exceeds number of public tokens");
        require(tokenPriceWhite.mul(tokensNumber) <= msg.value, "Ether value sent is too low");
        
        require(tokenPriceWhite.mul(tokensNumber) <= msg.value, "Ether value sent is too low");
        require(whitelistSaleActive, "Maybe later");
        require(tokensNumber > 0, "Wrong amount");
        require(tokensNumber <= whitelist[msg.sender], "You can't claim more than your allotment");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber + 1, "Tokens number to mint exceeds number of public tokens");

        for (uint i = 0; i < tokensNumber; i++) {
            require(whitelist[msg.sender] >= 1, "You don't have any more Borphols to claim");
            require(tokensNumber.sub(i) <= whitelist[msg.sender], "You can't claim more than your allotment");
            require(_tokenIdCounter.current()<= nftsPublicNumber + 1, "Sry I dont have enough left ;(");
            claimed[msg.sender] += 1;
            whitelist[msg.sender] =whitelist[msg.sender].sub(1);
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
        
    }
    
    function buy(uint tokensNumber) public payable {
        require(tokensNumber > 0, "Wrong amount");
        require(tokensNumber <= maxTokensPerTransaction, "Max tokens per transaction number exceeded");
        require(mainSaleActive, "Maybe later");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber, "Tokens number to mint exceeds number of public tokens");
        require(tokenPrice.mul(tokensNumber) <= msg.value, "Ether value sent is too low");

        for(uint i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }
    
}