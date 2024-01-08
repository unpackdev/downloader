// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

/**
 * @title CryptoFartPunks contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
 

contract CryptoFartPunks is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    uint public constant maxPunkPurchase = 14;
    uint256 public MAX_PUNKS = 4242;
    uint256 public constant punkPrice = 0.042 ether;
    string internal _baseTokenURI = "ipfs://QmTHMU6nUemoEQe53eBjvmE1jFcmqcWKTZYNmh9HL4HFXC/";
    address devAddress = 0x77C05D19E8eb588da1Dcf2dE430d01b5b3c25F07;
    address creator1Address = 0xdEa2C8F67383d2E7469aD679F01b718328a95070;
    address creator2Address = 0x5C7eb6e3c4224407FdB6b0e19aD620d7789644C9;
    address creator3Address = 0xF8E4B6DA85DB496AF8beFf22C47c8735b9bE2587;
    bool uriChangesLocked = false;
    bool saleStarted = false;

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

    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
    bytes memory tmp = bytes(_a);
    uint160 iaddr = 0;
    uint160 b1;
    uint160 b2;
    for (uint i = 2; i < 2 + 2 * 20; i += 2) {
        iaddr *= 256;
        b1 = uint160(uint8(tmp[i]));
        b2 = uint160(uint8(tmp[i + 1]));
        if ((b1 >= 97) && (b1 <= 102)) {
            b1 -= 87;
        } else if ((b1 >= 65) && (b1 <= 70)) {
            b1 -= 55;
        } else if ((b1 >= 48) && (b1 <= 57)) {
            b1 -= 48;
        }
        if ((b2 >= 97) && (b2 <= 102)) {
            b2 -= 87;
        } else if ((b2 >= 65) && (b2 <= 70)) {
            b2 -= 55;
        } else if ((b2 >= 48) && (b2 <= 57)) {
            b2 -= 48;
        }
        iaddr += (b1 * 16 + b2);
    }
    return address(iaddr);
}


    function mintPunks(uint numberOfTokens) public payable {
        require(saleStarted);
        require(numberOfTokens <= maxPunkPurchase, "Can only mint 14 (Fourt(een)) tokens at a time");
        require(totalSupply() + numberOfTokens <= MAX_PUNKS, "Purchase would exceed max supply of Punks");
        require(punkPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_PUNKS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function giftPunks(uint numberOfTokens, string memory addr) public payable {
        require(saleStarted);
        require(numberOfTokens <= maxPunkPurchase, "Can only mint 14 (Fourt (een)) tokens at a time");
        require(totalSupply() + numberOfTokens <= MAX_PUNKS, "Purchase would exceed max supply of Punks");
        require(punkPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        address friend_addr = parseAddr(addr);
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_PUNKS) {
                _safeMint(friend_addr, mintIndex);
            }
        }
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        if (!uriChangesLocked) {
            _baseTokenURI = baseURI;
        }
    }

    function lockChanges() public onlyOwner {
        uriChangesLocked = true;
    }

    function startSale() public onlyOwner {
        saleStarted = true;
    }

    function pauseSale() public onlyOwner {
        saleStarted = false;
    }

    function reservePunks(uint num) public onlyOwner {        
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(devAddress).transfer(balance/4.0);
        payable(creator1Address).transfer(balance/4.0);
        payable(creator2Address).transfer(balance/4.0);
        payable(creator3Address).transfer(balance/4.0);
    }
}