// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

/**
 * @title DopeDinos contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
 

contract DopeDinos is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    uint public constant maxDinoPurchase = 20;
    uint256 public MAX_DINOS = 9120;
    uint256 public constant dinoPrice = 0.04 ether;
    uint256 public saleStartTimestamp = 1529955500;
    string internal _baseTokenURI = "ipfs://QmauNgGg5sikRBRynDCZK3bYJGKRp8zBe1ecWhUe8FW6pw/";
    bool uriChangesLocked = false;
    address devAddress = 0x28033df10C84ED9585E0A680605fc0eAa024F8a2;
    address creator1Address = 0xF0140657bFE54A85b94530153cb0765ccd68a630;
    address creator2Address = 0x572D5356d4E7E43af5eAba2fb0ee86058818CeCf;
    address creator3Address = 0x5821Ecf65327F28292D0022aed8Ea59bC65FcfF1;
    address creator4Address = 0xa0C73E5d2E37FB8A26042B1Cb088Bb8DA25EFAc7;
    uint256 num_available = 100;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

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

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        if (!uriChangesLocked) {
            _baseTokenURI = baseURI;
        }
    }

    function lockChanges() public onlyOwner {
        uriChangesLocked = true;
    }

    function setNumAvailable(uint256 num) public onlyOwner {
        num_available = num;
    }

    function mintDinos(uint numberOfTokens) public payable {
        require( block.timestamp >= saleStartTimestamp, "Can't buy dinos until the sale has started!");
        require(numberOfTokens <= maxDinoPurchase, "Can only mint 20 tokens at a time");
        require(numberOfTokens <= num_available, "Purchase would exceed current supply of Dinos");
        require(totalSupply() + numberOfTokens <= MAX_DINOS, "Purchase would exceed max supply of Dinos");
        require(dinoPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        num_available = num_available - numberOfTokens;
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_DINOS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function reserveDinos(uint num) public onlyOwner {        
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(devAddress).transfer((balance/4.0) - (balance/40.0));
        payable(creator1Address).transfer((balance/4.0) - (balance/40.0));
        payable(creator2Address).transfer((balance/4.0) - (balance/40.0));
        payable(creator3Address).transfer((balance/4.0) - (balance/40.0));
        payable(creator4Address).transfer(balance/10.0);
    }
}