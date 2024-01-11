// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721Burnable.sol";

contract CryptoMolly is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, ERC721Burnable  {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint256 public constant MAX_TOKENS = 10000;
    uint256 public constant FREE_TOKENS = 1000;
    uint256 public constant MAX_WALLET = 5;
    bool public isSaleActive = true;
    uint256 private price = 0.0025 ether;

    constructor() ERC721("CryptoMolly", "CPM") {}

    function flipSaleStatus() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function Mint(string memory TokenURI) public payable returns (uint256) {

        uint256 rate;
   
        if (_tokenIdCounter.current() > 9000) {rate = 256;}
        else if (_tokenIdCounter.current() >= 8000) {rate = 128;}
        else if (_tokenIdCounter.current() >= 7000) {rate = 64;}
        else if (_tokenIdCounter.current() >= 6000) {rate = 32;}
        else if (_tokenIdCounter.current() >= 5000) {rate = 16;}
        else if (_tokenIdCounter.current() >= 4000) {rate = 8;}
        else if (_tokenIdCounter.current() >= 3000) {rate = 4;}
        else if (_tokenIdCounter.current() >= 2000) {rate = 2;}
        else if (_tokenIdCounter.current() >= 1000) {rate = 1;}
        else  {rate = 0;}

        require(isSaleActive, "Sale is currently not active");
        require(
            MAX_TOKENS > _tokenIdCounter.current(),
            "Not enough tokens left to buy."
        );
        require(balanceOf(msg.sender) < MAX_WALLET, 'You alreay own 5 CryptoMolly');
        require(msg.value >= price * rate, "Amount of ether sent not correct.");

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, TokenURI);
        return tokenId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
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
}
