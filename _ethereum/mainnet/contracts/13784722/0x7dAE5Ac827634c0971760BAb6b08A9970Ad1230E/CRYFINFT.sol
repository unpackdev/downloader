// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Pausable.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";


contract CRYFINFT is ERC721Pausable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;

    uint256 private _maxTokens = 8888;
    uint256 private _maxMint = 20;
    uint256 public _price = 100000000000000000;

    bool private _saleActive = false;

    mapping(address => uint256) private _minted;
    mapping(address => uint256[]) private _mintedIds;
    mapping(address => bool) private _whitelist;
    

    string private _prefixURI;
    string private _baseExtension;

    constructor() public ERC721("Crypto Fighter NFT SNS", "CRYFINFT") {
    }

    function mint(uint256 amount) public payable returns(uint256[] memory) {
        require(getSaleActive() || isWhitelisted(msg.sender), "Minting closed, sorry.");
        require(getTokensLeft() >= amount, "Trying to mint more tokens then tokens left.");
        require(_minted[msg.sender] + amount <= _maxMint, "Minting more then maximum per user.");
        require(msg.value >= amount * _price, "Not enought ETH sent.");

        uint256[] memory tokenIds = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            _tokenIds.increment();
            uint256 id = _tokenIds.current();
            _safeMint(msg.sender, id);
            _minted[msg.sender] += 1;
            _mintedIds[msg.sender].push(id);
            tokenIds[i] = id;
        }

        return tokenIds;
    }

    function getTokensLeft() public view returns (uint256) {
        return _maxTokens - _tokenIds.current();
    }

    function getTotalMinted() public view returns (uint256) {
        return _tokenIds.current();
    }

    function getSaleActive() public view returns (bool) {
        return _saleActive;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function getMintedIds(address addr) public view returns (uint256[] memory) {
        return _mintedIds[addr];
    }

    function isWhitelisted(address addr) public view returns (bool) {
        return _whitelist[addr];
    }

    function setMaxTokens(uint256 value) public onlyOwner {
        _maxTokens = value;
    }

    function setMaxMint(uint256 value) public onlyOwner {
        _maxMint = value;
    }

    function getMaxMint() public view returns (uint256) {
        return _maxMint;
    }

    function getMinstsLeft(address addr) public view returns (uint256) {
        return _maxMint - _minted[addr];
    }

    function setSaleActive(bool value) public onlyOwner {
        _saleActive = value;
    }

    function addToWhitelist(address[] memory addrs) public onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            _whitelist[addrs[i]] = true;
        }
    }

    function removeFromWhitelist(address[] memory addrs) public onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            _whitelist[addrs[i]] = false;
        }
    }

    function _removeToken(address from, uint256 tokenId) private {
        delete _mintedIds[from][tokenId];
    }

    function resetMintsForAddresses(address[] memory addrs) public onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            _minted[addrs[i]] = 0;
        }
    }

    function setPrice(uint256 price) public onlyOwner {
        _price = price;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        _prefixURI = uri;
    }

    function setBaseExtension(string memory _ext) public onlyOwner {
        _baseExtension = _ext;
    }

    function _baseURI() internal view override returns (string memory) {
        return _prefixURI;
    }
    
    function minted(address addr) public view returns (uint256) {
        return _minted[addr];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        tokenId.toString();
        return bytes(currentBaseURI).length > 0 ? string(
            abi.encodePacked(currentBaseURI, tokenId.toString(), _baseExtension)
        ) : "";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function play() public onlyOwner {
        _unpause();
    }

    function getPaused() public view returns(bool) {
        return paused();
    }

    // Allows minting(transfer from 0 address), but not transferring while paused() except from owner
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        if (!(from == address(0)) && !(from == owner())) {
            require(!paused(), "ERC721Pausable: token transfer while paused");
        }
        if (from != to) {
            if (from != address(0))
            {
                _removeToken(from, tokenId);
            }
        }
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0); 
        payable(msg.sender).transfer(address(this).balance);
    }

    
}