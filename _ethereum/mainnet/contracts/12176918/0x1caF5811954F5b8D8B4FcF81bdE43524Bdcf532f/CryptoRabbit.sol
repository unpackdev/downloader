// contracts/CryptoRabbit.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";

// Inspired by and modified from Chubbies (https://chubbies.io/) and BGANPUNKSV2 (https://bganpunks.eth.link/)
contract CryptoRabbit is ERC721, Ownable {

    using SafeMath for uint256;
    uint public constant MAX_RABBITS = 10000;
    bool public HAS_SALE_STARTED = true;
    string public METADATA_PROVENANCE_HASH = "";

    constructor(string memory baseURI) ERC721("CryptoRabbits","CRABBIT")  {
        setBaseURI(baseURI);
    }
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
    
    function calculatePrice() public view returns (uint256) {
        require(HAS_SALE_STARTED == true, "Sale hasn't started");
        require(totalSupply() < MAX_RABBITS, "Sale has already ended");

        uint currentSupply = totalSupply();
        if (currentSupply >= 9900) {
            return 990000000000000000;         // 9900-9999:  0.99 ETH
        } else if (currentSupply >= 9500) {
            return 590000000000000000;         // 9500-9500:  0.59 ETH
        } else if (currentSupply >= 7500) {
            return 390000000000000000;         // 7500-9500:  0.39 ETH
        } else if (currentSupply >= 3500) {
            return 190000000000000000;         // 3500-7500:  0.19 ETH
        } else if (currentSupply >= 1500) {
            return 90000000000000000;          // 1500-3499:  0.09 ETH
        } else if (currentSupply >= 500) {
            return 50000000000000000;          // 500-1499:   0.05 ETH 
        } else if (currentSupply >= 100) {
            return 30000000000000000;          // 100-499:    0.03 ETH
        } else {
            return 10000000000000000;          // 0-99:       0.01 ETH
        }
    }
    
    function adoptRabbit(uint256 numCryptoRabbit) public payable {
        require(totalSupply() < MAX_RABBITS, "Sale has already ended");
        require(numCryptoRabbit > 0 && numCryptoRabbit <= 20, "You can adopt minimum 1, maximum 20 CryptoRabbit");
        require(totalSupply().add(numCryptoRabbit) <= MAX_RABBITS, "Exceeds MAX_RABBITS");
        require(msg.value >= calculatePrice().mul(numCryptoRabbit), "Ether value sent is below the price");

        for (uint i = 0; i < numCryptoRabbit; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
            _setTokenURI(mintIndex, string(abi.encodePacked(toString(keccak256(abi.encodePacked(mintIndex, "rabbit"))), ".json")));
        }
    }

    function toString(bytes32 value) public pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }

    function toString(bytes memory data) public pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    // onlyOwner functions

    function setProvenanceHash(string memory _hash) public onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
    
    function startSale() public onlyOwner {
        HAS_SALE_STARTED = true;
    }
    
    function pauseSale() public onlyOwner {
        HAS_SALE_STARTED = false;
    }
    
    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}