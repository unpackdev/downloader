// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract BTNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public constant BT_GIFT = 200;
    uint256 public constant BT_PUBLIC = 4800;
    uint256 public constant BT_MAX = BT_PUBLIC + BT_GIFT;
    uint256 public constant BT_PRICE = 0.02 ether;
    uint256 public constant BT_PER_MINT = 5;
    uint256 public constant BT_PER_MINT_PRIVATE= 2;
    
    mapping(string => bool) private _usedNonces;
    
    string private _contractURI;
    string private _tokenBaseURI = "https://api.babytoadz.com/metadata/";
    address private _signerAddress = 0x927aEF5aC8CE905D2286084c48A1216513987d1c;
    address private _privateSignerAddress = 0xa5b69c2E15BdC33B32df777dC7c659e40176b259;

    string public proof;
    uint256 public giftedAmount;
    uint256 public publicAmountMinted;
    bool public saleLive;
    bool public locked;
    
    constructor() ERC721("Baby Toadz", "BT") {}
    
    modifier notLocked {
      require(!locked, "Contract metadata methods are locked");
      _;
    }

    function hashTransaction(address sender, uint256 qty, string memory nonce) private pure returns(bytes32) {
      bytes32 hash = keccak256(abi.encodePacked(
        "\x19Ethereum Signed Message:\n32",
        keccak256(abi.encodePacked(sender, qty, nonce)))
      );
      return hash;
    }
    
   function matchAddresSigner(bytes32 hash, bytes memory signature, bool isPrivate) private view returns(bool) {
      return (isPrivate ? _privateSignerAddress : _signerAddress) == hash.recover(signature);
    }
    
    function buy(bytes32 hash, bytes memory signature, string memory nonce, uint256 tokenQuantity) external payable {
      require(saleLive, "SALE_CLOSED");
      require(matchAddresSigner(hash, signature, false), "DIRECT_MINT_DISALLOWED");
      require(!_usedNonces[nonce], "HASH_USED");
      require(hashTransaction(msg.sender, tokenQuantity, nonce) == hash, "HASH_FAIL");
      require(totalSupply() < BT_MAX, "OUT_OF_STOCK");
      require(publicAmountMinted + tokenQuantity <= BT_PUBLIC, "EXCEED_PUBLIC");
      require(tokenQuantity <= BT_PER_MINT, "EXCEED_BT_PER_MINT");
      require(BT_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
      
      for(uint256 i = 0; i < tokenQuantity; i++) {
          publicAmountMinted++;
          _safeMint(msg.sender, totalSupply() + 1);
      }
      
      _usedNonces[nonce] = true;
    }

    function privateBuy(bytes32 hash, bytes memory signature, string memory nonce, uint256 tokenQuantity) external payable {
      require(saleLive, "SALE_CLOSED");
      require(matchAddresSigner(hash, signature, true), "DIRECT_MINT_DISALLOWED");
      require(!_usedNonces[nonce], "HASH_USED");
      require(hashTransaction(msg.sender, tokenQuantity, nonce) == hash, "HASH_FAIL");
      require(totalSupply() < BT_MAX, "OUT_OF_STOCK");
      require(publicAmountMinted + tokenQuantity <= BT_PUBLIC, "EXCEED_PUBLIC");
      require(tokenQuantity <= BT_PER_MINT_PRIVATE, "EXCEED_BT_PER_MINT");
      require(BT_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
      
      for(uint256 i = 0; i < tokenQuantity; i++) {
          publicAmountMinted++;
          _safeMint(msg.sender, totalSupply() + 1);
      }
      
      _usedNonces[nonce] = true;
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(totalSupply() + receivers.length <= BT_MAX, "MAX_MINT");
        require(giftedAmount + receivers.length <= BT_GIFT, "GIFTS_EMPTY");
        
        for (uint256 i = 0; i < receivers.length; i++) {
            giftedAmount++;
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function lockMetadata() external onlyOwner {
        locked = true;
    }
    
    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function setSignerAddress(address addr) external onlyOwner {
        _signerAddress = addr;
    }

    function setPrivateSignerAddress(address addr) external onlyOwner {
        _privateSignerAddress = addr;
    }

    function setBothSignerAddresses(address addr, address addr2) external onlyOwner {
        _signerAddress = addr;
        _privateSignerAddress = addr2;
    }    

    function setProvenanceHash(string calldata hash) external onlyOwner notLocked {
        proof = hash;
    }
    
    function setContractURI(string calldata URI) external onlyOwner notLocked {
        _contractURI = URI;
    }
    
    function setBaseURI(string calldata URI) external onlyOwner notLocked {
        _tokenBaseURI = URI;
    }    
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }
}