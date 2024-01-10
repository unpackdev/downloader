// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract NekoChan is ERC721URIStorage, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string public baseTokenURI;

    constructor() ERC721("NekoChan", "NEKO") {
    }

    function safeBatchMintNeko(address to, uint count) public onlyOwner returns (uint) {
        require (_tokenIds.current() + count <= 10000, "over total mint");
        require (count <= 50, "over max mint");
        for (uint i = 0; i < count; i++) {
            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();
            _safeMint(to, tokenId);
        }
        return count;
    }

    function batchTransfer(address[] calldata addressList, uint256[] calldata tokenIds) public {
        for (uint i = 0; i < addressList.length; i++) {
            _transfer(msg.sender, addressList[i], tokenIds[i]);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal onlyOwner override(ERC721, ERC721URIStorage) {
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

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory uri) public virtual onlyOwner {
        baseTokenURI = uri;
    }

    uint256 private _mintPrice;

    function mintPrice() public view returns (uint256) {
        return _mintPrice;
    }

    function setMintPrice(uint256 price) public onlyOwner {
        _mintPrice = price;
    }

    function deposit(uint256 amount) payable public {
        require(msg.value == amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(address payable _to) public onlyOwner {
        uint amount = address(this).balance;
        (bool success, ) = _to.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function mintNeko() public payable returns (uint256) {
        require (_tokenIds.current() <= 10000, "over total mint");

        deposit(_mintPrice);

        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
        return tokenId;
    }

    function batchMintNeko(uint256 count) public payable returns (uint256) {
        require (_tokenIds.current() + count <= 10000, "over total mint");
        require (count <= 50, "Max 50 nekochan in one time");

        uint256 totalPrice = _mintPrice * count;
        
        deposit(totalPrice);
        
        for (uint i = 0; i < count; i++) {
            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();
            _safeMint(msg.sender, tokenId);
        }
        return count;
    }
}
