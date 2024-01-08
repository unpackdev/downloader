// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./ECDSA.sol";

contract Paranoia is ERC721Enumerable, Ownable {
    
    using Strings for uint256;
    using ECDSA for bytes32;
    
    int256 public availableStock = 600;
    
    uint256 public price = 200000000000000000;
    
    uint256 public totalCount; 
    uint256 public publicCount;
    uint256 public reservedCount;
    
    uint256 public reservedMax = 400;
    uint256 public publicMax = 600;
    
    address private _signerAddress = 0xCC1f59045168fEF4a88b90FB0a9B492Ef3eBa218;
    
    string public baseURI;
    
    mapping(string => bool) private _usedNonces;

    constructor(string memory name_, string memory symbol_, string memory baseURI_) ERC721(name_, symbol_) {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
    
    function setSignerAddress(address _newAddress) public onlyOwner {
        _signerAddress = _newAddress;
    }
    
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }
    
    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }
    
    function setAvailableStock(int256 _availableStock) public onlyOwner {
        availableStock = _availableStock;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '.json';
    }
    
    function hashTransaction(string memory nonce) private pure returns(bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(nonce)))
        );
        return hash;
    }
    
    function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return _signerAddress == hash.recover(signature);
    }
    
    function claimReservation(bytes32 hash, bytes memory signature, string memory nonce ) public {
        require(reservedCount + 1 <= reservedMax, "Sold out");
        require(matchAddresSigner(hash, signature), "Invalid signature");
        require(!_usedNonces[nonce], "Hash already used");
        require(hashTransaction(nonce) == hash, "Invalid hash");
        reservedCount++;
        _safeMint(_msgSender(), 1 + totalCount++);
        _usedNonces[nonce] = true;
    }
    
    function mint() payable public {
        require(availableStock - 1 >= 0, "No stock avaiable");
        require(publicCount + 1 <= publicMax, "Sold out");
        require(msg.value >= price, "Insufficient funds, please check price");
        payable(owner()).transfer(msg.value);
        availableStock--;
        publicCount++;
        _safeMint(_msgSender(), 1 + totalCount++);
    }
    
}