// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

contract OkayTownWTF is ERC721A, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 2000000000000000;
  uint256 public maxSupply = 7777;
  bool public publicsale = true;

  mapping(address => uint256) public freeMintedBalance;
  mapping(address => uint256) public publicMintedBalance;

  constructor() ERC721A("okaytown.wtf", "OKTO") {
  }

  // ====== Settings ======
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "Cannot be called by a contract");
    _;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  function _startTokenId() internal pure override returns (uint256){
    return 1;
  }
  //

  // ====== Public ======
  function mint(uint256 _mintAmount) public payable callerIsUser {
    uint256 supply = totalSupply();
    
    require(publicsale, "publicsale is not active");
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if(supply < 1777){
      require(_mintAmount == 1, "only 1 nft per address");
      require(freeMintedBalance[msg.sender] < 1, "already claimed");
        
      freeMintedBalance[msg.sender]++;
    } else {
      require(publicMintedBalance[msg.sender] + _mintAmount <= 10, "max NFT per wallet exceeded");
      require(msg.value >= cost * _mintAmount, "insufficient funds");

      publicMintedBalance[msg.sender] += _mintAmount;
    }

    _safeMint(msg.sender, _mintAmount);
  }
  
  // ====== Owner ======
  function ownerMint(uint256 _mintAmount) public onlyOwner {
    // Amount Control
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
    //

    _safeMint(msg.sender, _mintAmount);
  }

  // ====== View ======
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  /// @dev Returns the tokenIds of the address. O(totalSupply) in complexity.
  function tokensOfOwner(address owner) external view returns (uint256[] memory) {
    unchecked {
        uint256[] memory a = new uint256[](balanceOf(owner)); 
        uint256 end = _currentIndex;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        for (uint256 i; i < end; i++) {
            TokenOwnership memory ownership = _ownerships[i];
            if (ownership.burned) {
                continue;
            }
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                a[tokenIdsIdx++] = i;
            }
        }
        return a;    
    }
  }

  // ====== Only Owner ======
  // Cost and Limits
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setPublicsale() public onlyOwner {
    publicsale = !publicsale;
  }
  //

  // Metadata
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  //

  function withdraw() public payable onlyOwner {
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}