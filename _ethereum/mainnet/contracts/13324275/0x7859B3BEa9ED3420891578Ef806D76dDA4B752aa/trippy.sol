// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ECDSA.sol";

contract TrippyMints is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public constant trippyPublic = 7500;
    uint256 public constant trippyPresale = 500;
    uint256 public constant trippyReserved = 80;
    uint256 public constant trippyTotal = 8080;
    uint256 public constant trippyMaxPerTx = 10;
    uint256 public constant price = 0.05 ether;

    mapping(address => bool) private _privateSaleEntries;
    mapping(address => uint256) private _privateSaleBuys;
    mapping(string => bool) private _previousNonces;
    
    address private _developerAddress = 0x755f8F2019C00CbfDd50a07b7ED607A3fe5C3550;
    string private _tokenBaseURI;
    address private _serverPublicKey;

    string public pHash;
    uint256 public giftCounter;
    uint256 public publicCounter;
    uint256 public privateCounter;
    uint256 public privateSaleLimit = 5;

    bool public live;
    bool public privateSaleActive;
    bool public editable;
    
    modifier onlyEditable {
        require(editable, "METADATA_FUNCTIONS_LOCKED");
        _;
    }
    
    constructor() ERC721("Trippy Mints", "TRIP") {
        _tokenBaseURI = "https://trippymints.com/api/metadata/";
        _serverPublicKey = 0x1D78Dcd7888b6DdB9acF465F46EBC477DB42e151;
    }
    
    function insertPrivateSalers(address[] calldata privateEntries) external onlyOwner {
        for(uint256 i = 0; i < privateEntries.length; i++) {
            require(privateEntries[i] != address(0), "NULL_ADDRESS");
            require(!_privateSaleEntries[privateEntries[i]], "DUPLICATE_ENTRY");

            _privateSaleEntries[privateEntries[i]] = true;
        }   
    }

    function removePrivateSalers(address[] calldata privateEntries) external onlyOwner {
        for(uint256 i = 0; i < privateEntries.length; i++) {
            require(privateEntries[i] != address(0), "NULL_ADDRESS");
            
            _privateSaleEntries[privateEntries[i]] = false;
        }
    }
    
    // anti bot code - s/o SVS
    function hashTransaction(address sender, uint256 qty, string memory nonce) public pure returns(bytes32) {
          bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, qty, nonce)))
          );
          
          return hash;
    }
    
    function matchAddressSigner(bytes32 hash, bytes memory signature) public view returns(bool) {
        return _serverPublicKey == hash.recover(signature);
    }
    
    function mint(bytes32 hash, bytes memory signature, string memory nonce, uint256 qty) external payable {
        require(live, "Sale is currently closed.");
        require(!privateSaleActive, "Only presalers are allowed at the moment.");
        require(totalSupply() < trippyTotal, "The sale is sold out.");
        require(matchAddressSigner(hash, signature), "You are only allowed to mint through the website.");
        require(!_previousNonces[nonce], "You have already purchased your presale allocation.");
        require(hashTransaction(msg.sender, qty, nonce) == hash, "You are only allowed to mint through the website.");
        require(publicCounter + qty <= trippyPublic, "Not enough Trips left.");
        require(qty <= trippyMaxPerTx, "You can purchase up to 10 Trips per transaction.");
        require(price * qty <= msg.value, "You didn't send enough ETH.");
        
        for(uint256 i = 0; i < qty; i++) {
            publicCounter++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
        
        _previousNonces[nonce] = true;
    }
    
    function privateBuy(uint256 qty) external payable {
        require(!live && privateSaleActive, "Presale is currently closed.");
        require(_privateSaleEntries[msg.sender], "You are not qualified for the presale.");
        require(totalSupply() < trippyTotal, "The sale is sold out.");
        require(privateCounter + qty <= trippyPresale, "Not enough Trips left in the presale.");
        require(_privateSaleBuys[msg.sender] + qty <= privateSaleLimit, "You can only purchase up to 5 Trips in the presale.");
        require(price * qty <= msg.value, "You didn't send enough ETH.");
        
        for (uint256 i = 0; i < qty; i++) {
            privateCounter++;
            _privateSaleBuys[msg.sender]++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }
    
    function reserve(address[] calldata reservers) external onlyOwner {
        require(totalSupply() + reservers.length <= trippyTotal, "Sold out.");
        require(giftCounter + reservers.length <= trippyReserved, "NO_RESERVED_LEFT");
        
        for (uint256 i = 0; i < reservers.length; i++) {
            giftCounter++;
            _safeMint(reservers[i], totalSupply() + 1);
        }
    }
    
    function withdraw() external onlyOwner {
        payable(_developerAddress).transfer(address(this).balance / 10);
        payable(owner()).transfer(address(this).balance);
    }
    
    function isInPrivateSale(address addr) external view returns (bool) {
        return _privateSaleEntries[addr];
    }
    
    function privateHasPurchasedCount(address addr) external view returns (uint256) {
        return _privateSaleBuys[addr];
    }
    
    function setEditable() external onlyOwner {
        editable = false;
    }
    
    function toggle() external onlyOwner {
        live = !live;
    }
    
    function togglePresaleStatus() external onlyOwner {
        privateSaleActive = !privateSaleActive;
    }
        
    function setServerPublicKey(address addr) external onlyOwner {
        _serverPublicKey = addr;
    }
    
    function setBaseURI(string calldata URI) external onlyOwner onlyEditable {
        _tokenBaseURI = URI;
    }
    
    function setProvenanceHash(string calldata hash) external onlyOwner {
        pHash = hash;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }
}