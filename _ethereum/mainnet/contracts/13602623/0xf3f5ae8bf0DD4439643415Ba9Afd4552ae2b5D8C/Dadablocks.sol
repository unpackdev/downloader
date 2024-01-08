// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
// import "./ERC721URIStorage.sol";
// import "./Pausable.sol";
import "./Ownable.sol";
// import "./Counters.sol";
import "./ECDSA.sol";
import "./console.sol";

contract Dadablocks is ERC721Enumerable, Ownable {
    
    using ECDSA for bytes32;
  
  // Provenance
  string public DadaBlocks_HASH = "";
  
  // AntiBot
  address private _signerAddress = 0x293946991B6bF14D3F8ab772744eADCe9c0BEb61;


  // Price & Supply
  uint256 public constant DD_RESERVE = 100;
  uint256 public constant NFT_PRICE = 10000000000000000; //0.01 ETH
  uint public constant MAX_SUPPLY = 1000;

  // Internals
  string private _baseTokenURI;
  
  // Sale
  bool public hasSaleStarted = false;
  uint private constant MAX_MINT_PER_CALL = 4;

  // Pre-Sale
  bool public hasPreSaleStarted = false;
  uint public constant MAX_PRESALE_SUPPLY = 100;
  uint256 public presaleMaxMint = 4;
  
  mapping (address => bool) private presaleList;
  mapping (address => uint256) private presaleListClaimed;
  mapping (string => bool) private _usedNonces;
  

  constructor(string memory baseURI) ERC721("Dadablocks", "DDB") {
    setBaseURI(baseURI);
  }

  function _baseURI() internal view override(ERC721) returns (string memory) {        
    return _baseTokenURI;
  }
  
  function hashTransaction(address sender, uint256 qty, string memory nonce) private pure returns(bytes32) {
      bytes32 hash = keccak256(abi.encodePacked(
        "\x19Ethereum Signed Message:\n32",
        keccak256(abi.encodePacked(sender, qty, nonce)))
      );
      return hash;
    }
    
    function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return _signerAddress == hash.recover(signature);
    }
    

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }
  
    
  function addToPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(! presaleList[entry], "DUPLICATE_ENTRY");
             presaleList[entry] = true;
        }   
    }

  function removeFromPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            
             presaleList[entry] = false;
        }
    }
    
  function onPreSaleList(address addr) external view returns (bool) {
        return presaleList[addr];
    }
    
  function presalePurchasedCount(address addr) external view returns (uint256) {
        return presaleListClaimed[addr];
    }

  
  function getBaseURI() external view returns(string memory) {
    return _baseTokenURI;
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

  function reserve() public onlyOwner {
    require(totalSupply() < DD_RESERVE, "Reservation claimed");
    for (uint i = 0; i < DD_RESERVE; i++) {
      uint mintIndex = totalSupply() + 1; // +1 so it doesn't start on index 0.
      _safeMint(msg.sender, mintIndex);
    }    
  }

  function mintPreSale(uint256 numberOfTokens) public payable { 
    require(hasPreSaleStarted, "Presale has not started");
    require(presaleList[msg.sender], "You are not on the Presale List");
    require(msg.value >= NFT_PRICE * (numberOfTokens), "Incorrect ether value");
    require(totalSupply() < MAX_PRESALE_SUPPLY, "Presale has ended");
    require(
            presaleListClaimed[msg.sender] + (numberOfTokens) <=
            presaleMaxMint,
            "Purchase exceeds max allowed"
        );
    require(
            numberOfTokens > 0 && numberOfTokens <= presaleMaxMint,
            "Cannot purchase this many tokens"
        );

    for (uint256 i = 0; i < numberOfTokens; i++) {
        uint256 mintIndex = totalSupply() + 1;
        if (totalSupply() < MAX_SUPPLY) {
            presaleListClaimed[msg.sender] += 1;
            _safeMint(msg.sender, mintIndex);
        }
    }
  }

// , bytes32 hash, bytes memory signature, string memory nonce

  function Mint(uint256 numNFTs, bytes32 hash, bytes memory signature, string memory nonce) public payable {
    require(hasSaleStarted, "Sale has not started");
    require(MAX_SUPPLY > totalSupply(), "Sale has ended");
    require(matchAddresSigner(hash, signature), "DIRECT_MINT_DISALLOWED");
    require(!_usedNonces[nonce], "HASH_USED");
    require(hashTransaction(msg.sender, numNFTs, nonce) == hash, "HASH_FAIL");
    require(numNFTs > 0 && numNFTs <= MAX_MINT_PER_CALL, "Exceeds MAX_MINT_PER_CALL");
    require(MAX_SUPPLY >= totalSupply() + numNFTs, "Exceeds MAX_SUPPLY");
    require(msg.value >= NFT_PRICE * numNFTs, "Incorrect ether value");

    for (uint i = 0; i < numNFTs; i++) {
      uint mintIndex = totalSupply() + 1; // +1 so it doesn't start on index 0.
      _safeMint(msg.sender, mintIndex);
    }    
    _usedNonces[nonce] = true;
  }
 
  function flipPreSaleState() public onlyOwner {
    hasPreSaleStarted = !hasPreSaleStarted;
  }
  
  function flipSaleState() public onlyOwner {
    hasSaleStarted = !hasSaleStarted;
  }

  function withdraw() public onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }

  // function _beforeTokenTransfer(address from, address to, uint256 tokenId)
  //   internal
  //   override(ERC721, ERC721Enumerable)
  // {
  //   super._beforeTokenTransfer(from, to, tokenId);
  // }

  // function _burn(uint256 tokenId) internal override(ERC721) {
  //   super._burn(tokenId);
  // }

  // function tokenURI(uint256 tokenId)
  //   public
  //   view
  //   override(ERC721)
  //   returns (string memory)
  // {
  //   return super.tokenURI(tokenId);
  // }
  // function supportsInterface(bytes4 interfaceId)
  //   public
  //   view
  //   override(ERC721, ERC721Enumerable)
  //   returns (bool)
  // {
  //   return super.supportsInterface(interfaceId);
  // }

  function setProvenanceHash(string memory provenanceHash) public onlyOwner {
    DadaBlocks_HASH = provenanceHash;
  }
}
