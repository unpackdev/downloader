// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract CoinApesNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public constant CA_AIRDROP_VOLUME = 300;
    uint256 public constant CA_PUBLIC_VOLUME = 4144;
    uint256 public constant CA_MAX_VOLUME = CA_PUBLIC_VOLUME + CA_AIRDROP_VOLUME;
    uint256 public constant CA_PRICE = 0.06 ether;
    uint256 public constant CA_PER_MINT_PUBLIC = 3;
    uint256 public constant CA_PER_MINT_WHITELIST = 1;
    
    mapping(string => bool) private _usedNonces;
    mapping(address => uint256) private _usedAddresses;
    mapping(address => uint256) private _usedWhitelistAddresses;
    
    string private _contractURI;
    string private _tokenBaseURI = "https://api.coinapes.io/metadata/";
    address private _signerAddress = 0x755701d985fA2f073f349cFF87D31f1FaD95002e;
    address private _whitelistSignerAddress = 0xB0949c5dcFc882b0BF796c86AE150670E446dC65 ;

    string public proof;
    uint256 public giftedAmount;
    uint256 public publicAmountMinted;
    bool public saleLive;
    bool public locked;
    
    constructor() ERC721("Coin Apes", "APE") {}
    
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
      return (isPrivate ? _whitelistSignerAddress : _signerAddress) == hash.recover(signature);
    }
    
    function buy(bytes32 hash, bytes memory signature, string memory nonce, uint256 tokenQuantity) external payable {
      require(saleLive, "SALE_CLOSED");
      require(matchAddresSigner(hash, signature, false), "DIRECT_MINT_DISALLOWED");
      require(!_usedNonces[nonce], "HASH_USED");
      require(hashTransaction(msg.sender, tokenQuantity, nonce) == hash, "HASH_FAIL");
      require(totalSupply() < CA_MAX_VOLUME, "OUT_OF_STOCK");
      require(publicAmountMinted + tokenQuantity <= CA_PUBLIC_VOLUME, "EXCEED_PUBLIC");
      require(tokenQuantity <= CA_PER_MINT_PUBLIC, "EXCEED_CA_PER_MINT");
      require(CA_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
      require(_usedAddresses[msg.sender] + tokenQuantity <= CA_PER_MINT_PUBLIC, "EXCEED_ALLOC");
      
      for(uint256 i = 0; i < tokenQuantity; i++) {
          publicAmountMinted++;
          _usedAddresses[msg.sender]++;
          _safeMint(msg.sender, totalSupply() + 1);
      }
      
      _usedNonces[nonce] = true;
    }

    function whitelistBuy(bytes32 hash, bytes memory signature, string memory nonce, uint256 tokenQuantity) external payable {
      require(saleLive, "SALE_CLOSED");
      require(matchAddresSigner(hash, signature, true), "DIRECT_MINT_DISALLOWED");
      require(!_usedNonces[nonce], "HASH_USED");
      require(hashTransaction(msg.sender, tokenQuantity, nonce) == hash, "HASH_FAIL");
      require(totalSupply() < CA_MAX_VOLUME, "OUT_OF_STOCK");
      require(publicAmountMinted + tokenQuantity <= CA_PUBLIC_VOLUME, "EXCEED_PUBLIC");
      require(tokenQuantity <= CA_PER_MINT_WHITELIST, "EXCEED_CA_PER_MINT");
      require(CA_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
      require(_usedWhitelistAddresses[msg.sender] + tokenQuantity <= CA_PER_MINT_WHITELIST, "EXCEED_ALLOC");

      for(uint256 i = 0; i < tokenQuantity; i++) {
          publicAmountMinted++;
          _usedWhitelistAddresses[msg.sender]++;
          _safeMint(msg.sender, totalSupply() + 1);
      }
      
      _usedNonces[nonce] = true;
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(totalSupply() + receivers.length <= CA_MAX_VOLUME, "MAX_MINT");
        require(giftedAmount + receivers.length <= CA_AIRDROP_VOLUME, "AIRDROP_EMPTY");
        
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
        _whitelistSignerAddress = addr;
    }

    function setBothSignerAddresses(address addr, address addr2) external onlyOwner {
        _signerAddress = addr;
        _whitelistSignerAddress = addr2;
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