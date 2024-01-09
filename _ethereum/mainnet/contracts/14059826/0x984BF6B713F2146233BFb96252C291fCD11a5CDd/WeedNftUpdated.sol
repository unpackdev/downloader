pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicensed
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract NFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;  
  string public baseExtension = ".json";    
  uint256 public cost = 0.04 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmount = 5;
  uint256 public claimedCount = 0; 
  uint256 public maxClaimLimitAmount = 100;
  bool public paused = false;
  bool public revealed = true;
  string public notRevealedUri;    
  address public claimerAddress;


  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,           
    string memory _initNotRevealedUri,
    address _claimer     //if we dont want to show thw actual(base) url put other url
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    claimerAddress = _claimer; 

  }

  modifier onlyClaimer() {
        require(claimerAddress == _msgSender(), "caller is not the claimer");
        _;
  }


  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {  //
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount);  //if not owner charge fee to mint
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {  
      _safeMint(msg.sender, supply + i);   //mint to the adress the id
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
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxClaimLimitAmount(uint256 _newmaxClaimLimitAmount) public onlyOwner {
    maxClaimLimitAmount = _newmaxClaimLimitAmount;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
   
  }

  function setClaimaddress(address newClaimer) public onlyOwner {
          claimerAddress = newClaimer;  
  }

  function claimfree(uint256 _mintAmount, address _addr) public onlyClaimer {  //
    uint256 supply = totalSupply();
    require(!paused,"Mint Paused");
    require(_mintAmount > 0,"Mint amount cann't be zero");
    require(maxClaimLimitAmount>= claimedCount + _mintAmount,"Claim Limit reached");
    require(supply + _mintAmount <= maxSupply,"Out of supply");
    for (uint256 i = 1; i <= _mintAmount; i++) {  
      _safeMint(_addr, supply + i);   //mint to the adress the id
    }
    claimedCount = claimedCount + _mintAmount;
  }
}