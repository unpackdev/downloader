// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

/*
####### ######  ### ######  ######  ### #######    #     # #######    #    ######  ####### 
   #    #     #  #  #     # #     #  #  #          #     # #         # #   #     #      #  
   #    #     #  #  #     # #     #  #  #          #     # #        #   #  #     #     #   
   #    ######   #  ######  ######   #  #####      ####### #####   #     # #     #    #    
   #    #   #    #  #       #        #  #          #     # #       ####### #     #   #     
   #    #    #   #  #       #        #  #          #     # #       #     # #     #  #      
   #    #     # ### #       #       ### #######    #     # ####### #     # ######  ####### 

*/

contract TrippieHeadz is ERC721Enumerable, Ownable {
    
  using Strings for uint256;

  string public baseURI;
  string public contractURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  
  
  uint256 public constant COST = 0.099 ether;
  uint256 public constant MAXSUPPLY = 9999;
  uint256 public constant PRESALE_SUPPLY = 6000;
  uint256 public constant RESERVED_SUPPLY = 99;
  uint256 public constant TOTALSALECOUNT = MAXSUPPLY - RESERVED_SUPPLY;
  uint256 public constant MAXMINTAMOUNT = 3;
  uint256 public constant NFTPERADDRESSLIMIT = 9;
  

  bool public paused = false;
  bool public revealed = false;
  bool public isPresaleActive = false;
  bool public isPublicSaleActive = false;

  
  mapping(address => bool) private _presaleEligible;
  mapping(address => uint256) private _presaleClaimed;
  mapping(address => uint256) private _totalClaimed;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    string memory _initContractURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    setContractUri(_initContractURI);
  }
  
  modifier onlyPresale() {
      require(isPresaleActive, "PRESALE_NOT_ACTIVE");
      _;
  } 
  
  
  modifier onlyPublicSale() {
      require(isPublicSaleActive, "PUBLIC_SALE_NOT_ACTIVE");
      _;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  // presale 
  function addToPresaleList(address[] calldata addresses) external onlyOwner {
      for(uint256 i =0; i < addresses.length; i++) {
          require(addresses[i] != address(0), "NULL_ADDRESS");
          require(!_presaleEligible[addresses[i]], "DUPLICATE_ENTRY");
          
          _presaleEligible[addresses[i]] = true;
          _presaleClaimed[addresses[i]] = 0;
      }
  }
  
  function removeFromPresaleList(address[] calldata addresses) external onlyOwner {
      for(uint256 i = 0; i < addresses.length; i++) {
          
          require(addresses[i] != address(0), "NULL_ADDRESS");
          require(_presaleEligible[addresses[i]], "NOT_IN_PRESALE");
          
          _presaleEligible[addresses[i]] = false;
      }
  }
  
  function isEligibleForPresale(address addr) external view returns (bool) {
      require(addr != address(0), "NULL_ADDRESS");
      
      return _presaleEligible[addr];
  }
  
  function hasClaimedPresale(address addr) external view returns (bool) {
      require(addr != address(0), "NULL_ADDRESS");
      return _presaleClaimed[addr] == 1;
  }
  
  
  function togglePresaleStatus() external onlyOwner {
      isPresaleActive = !isPresaleActive;
  }
  
  function togglePublicSaleStatus() external onlyOwner {
      isPublicSaleActive = !isPublicSaleActive;
  }
  
  

  // public
  
  function claimReserved(uint256 quantity, address addr) external onlyOwner {
      require(totalSupply() >= TOTALSALECOUNT, "MUST_REACH_MAX_SUPPLY");
      require(totalSupply() < MAXSUPPLY, "SOLD_OUT");
      require(totalSupply() + quantity <= MAXSUPPLY, "EXCEEDS_TOTAL");
      
      _safeMint(addr, totalSupply() + 1);
  }
  
 
  
  function claimPresale() external payable onlyPresale {
      uint256 quantity = 1;
      
      require(_presaleEligible[msg.sender], "NOT_ELEGIBLE");
      require(_presaleClaimed[msg.sender] < 1, "ALREADY_CLAIMED");
      
      
      require(totalSupply() < PRESALE_SUPPLY, "PRESALE_SOLD_OUT");
      require(totalSupply() + quantity <= PRESALE_SUPPLY, "EXCEEDS_PRESALE_SUPPLY");
      
      require(COST * quantity == msg.value, "INVALID_ETH_AMOUNT");
      
      for (uint256 i = 0; i < quantity; i++) {
          _presaleClaimed[msg.sender] += 1;
          _safeMint(msg.sender, totalSupply() + 1);
      }
  }
  
  
  function mint(uint256 quantity) external payable onlyPublicSale {
    require(!paused, "the contract is paused");
    require(tx.origin == msg.sender, "GO_AWAY_BOT");
    
    require(totalSupply() < TOTALSALECOUNT, "SOLD_OUT");
    require(quantity > 0, "QUANTITY_CANNOT_BE_ZERO");
    require(quantity <= MAXMINTAMOUNT, "max mint amount per session exceeded");
    require(totalSupply() + quantity <= TOTALSALECOUNT, "EXCEEDS_MAX_SUPPLY");
    require(_totalClaimed[msg.sender] + quantity <= NFTPERADDRESSLIMIT, "EXCEEDS_MAX_ALLOWANCE");
    require(COST * quantity == msg.value, "INVALID_ETH_AMOUNT");
    
    for(uint256 i = 0; i < quantity; i++) {
        _totalClaimed[msg.sender] += 1;
        _safeMint(msg.sender, totalSupply() + 1);
    }
    
  }
  

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

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
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }
  

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
 
  function setContractUri(string memory _newContractURI) public onlyOwner {
    contractURI = _newContractURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
 
  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("0xc3E7456FAC3C2f7D737CF0B016fbB250F7650204"); // middle wallet 
    require(os);

  }
  
  
}