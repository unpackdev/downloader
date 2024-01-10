//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";

import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";



contract BadGirlNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint public MINT_PRICE = 0.05 ether;
    uint32 public PRE_SALE_DATE = 1645358400;
    uint32 public PUBLIC_SALE_DATE = 1645963200;
    address public COUNTER_ADDRESS = 0xDE5C4a42C9E3A16b967aa64367356D9Bc0f689f8;
    string baseURI = '';

    constructor() ERC721("BadGirlNFT", "BadGirl") {}

    function batchMint(address recipient, uint amount) public payable returns (bool) {
        require(block.timestamp >= PRE_SALE_DATE, "Public sale has not yet started!");
        require(msg.value >= MINT_PRICE * amount, "Not enough ETH sent; check price!"); 
        (bool sent,) = COUNTER_ADDRESS.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        for (uint i = 0; i < amount; ++i) {
            _mintNFT(recipient);
        }
        return true;
    }

    function _mintNFT(address recipient) private returns (uint256)
    {
        // prevent oversold
        if (_tokenIds.current() >= 99 && block.timestamp < PUBLIC_SALE_DATE) {
            return 0;
        }
        if (_tokenIds.current() >= 6666) {
            return 0;
        }
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, Strings.toString(newItemId));
        return newItemId;
    }

    function setBaseURI (string calldata uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return 'https://pin.ski/3s4OUyc';
        }
        return super.tokenURI(tokenId);
    }

}