// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";

// import "./ERC721Tradeble.sol";

contract Kids4Kids is ERC721, ERC721URIStorage, Ownable, ERC721Enumerable {
    using Counters for Counters.Counter;

    mapping(string => uint8) public existingURIs;

    Counters.Counter private _tokenIdCounter;
    uint256 public priceOfOne;
    uint8 public canMint;

    constructor() ERC721("Kids4Kids", "K4K") {
        //set initial price
        priceOfOne = 0.1 ether;
        canMint = 1;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
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

    function setCanMint(uint8 _newVal) public onlyOwner {
        //set if user can mint
        canMint = _newVal;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setPrice(uint256 _newVal) public onlyOwner {
        //set price of an NFT
        priceOfOne = _newVal;
    }

    // function safeMint(address to, string memory uri) public onlyOwner {
    //     uint256 tokenId = _tokenIdCounter.current();
    //     _tokenIdCounter.increment();
    //     _safeMint(to, tokenId);
    //     _setTokenURI(tokenId, uri);
    // }

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

    function metadataToOwner(string memory metadataURI)
        public
        returns (address owner)
    {}

    function payToMint(address recipient, string memory metadataURI)
        public
        payable
        returns (uint256)
    {
        require(canMint == 1, "You cannot pay to mint!");
        require(existingURIs[metadataURI] != 1, "NFT already minted!");
        require(msg.value >= priceOfOne, "Please pay the required amount!");

        uint256 newItemId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        existingURIs[metadataURI] = 1;

        _mint(recipient, newItemId);
        _setTokenURI(newItemId, metadataURI);

        return newItemId;
    }

    function isContentOwned(string memory uri) public view returns (bool) {
        return existingURIs[uri] == 1;
    }

    function count() public view returns (uint256) {
        return _tokenIdCounter.current();
    }
}
