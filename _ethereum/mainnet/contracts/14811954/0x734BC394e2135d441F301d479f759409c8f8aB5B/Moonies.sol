// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract Moonies is ERC721, Ownable {
    using Counters for Counters.Counter;
    uint256 public constant MAX_TOKENS = 8888;
    uint256 public constant TOKEN_COST = 0.035 * 1e18;
    string baseURI = "https://metadata.mooniesnft.xyz/";
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Moonies", "MOON") {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function changeBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    // Additional functions

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    modifier costs(uint256 _cost) {
        require(msg.value >= _cost, "Insufficient funds.");
        _;
    }

    function mint() public payable costs(TOKEN_COST) {
        require(totalSupply() < MAX_TOKENS, "Minting limit reached.");
        address to = msg.sender;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function mintMany(uint256 _amount)
        public
        payable
        costs(TOKEN_COST * _amount)
    {
        require(totalSupply() + _amount < MAX_TOKENS, "Minting limit reached.");
        address to = msg.sender;
        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();    
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
        }
    }

    function mintOwner() public onlyOwner {
        require(totalSupply() < MAX_TOKENS, "Minting limit reached.");
        address to = msg.sender;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function mintOwnerMany(uint256 _amount) public onlyOwner {
        require(
            totalSupply() + _amount <= MAX_TOKENS,
            "Minting limit reached."
        );
        address to = msg.sender;
        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
        }
    }
}
