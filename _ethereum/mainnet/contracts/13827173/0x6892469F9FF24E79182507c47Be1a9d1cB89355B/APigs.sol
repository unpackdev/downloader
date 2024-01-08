 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Boom.sol";
import "./BabyPigs.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Counters.sol";

contract APigs is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
  string public baseTokenURI;

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
            return super.supportsInterface(interfaceId);
        }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, amount);
    }
  
  
  using Counters for Counters.Counter;
  Counters.Counter public _tokenSupply;

  uint256 public breedPrice = 500;
  uint256 private _price = 0.05 ether;
  uint256 private _reserved = 33;  

  uint256 public maxAmount = 8;
  bool public paused = true;
  bool public publicMintPaused = true;
  bytes32 public _rootHash ;

  
  mapping(address => uint256) private walletCount;
  Boom private boomContract;
  BabyPigs private babyPigsContract;

  modifier aPigsOwner(uint256 _aPigId) {
    require(ownerOf(_aPigId) == msg.sender, "Pig does not belong to sender");
    _;
  }

  constructor(string memory baseURI) ERC721("AlmightyPigs", "APIGS") {
    setBaseURI(baseURI);
  }

    
  function mintPreSale(bytes32[] memory _proof, uint256 num) external payable nonReentrant {
    uint256 supply = _tokenSupply.current();
    require(!paused, "Minting paused");
    require(publicMintPaused, "The Presale is over!");
    bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_proof, _rootHash, _leaf), " Address is not whitelisted");
    require( num > 0 && num < 3, " Max 2 per txn");
    require(walletCount[msg.sender] + num <= 2, " Whitelist only can mint 2");
    require(supply + num <= 3333 - _reserved, "Exceeds maximum supply");
    require(msg.value >= _price * num, "Ether sent is not correct");

    for (uint256 i = 1; i <= num; i++) {
      _safeMint(msg.sender, supply + i);
      _tokenSupply.increment();
    }

    walletCount[msg.sender] += num;
    
  }
  
  
  
  function mint(uint256 num) external payable nonReentrant {
    uint256 supply = _tokenSupply.current();
    require(!paused, "Minting paused");
    require(!publicMintPaused, " Public sale is not live yet");
    require( num > 0 && num < 3, " Max 2 per txn");
    require(supply + num <= 3333 - _reserved, "Exceeds maximum supply");
    require(
      walletCount[msg.sender] + num <= maxAmount,
      " Max Amount is reached!"
    );
    require(msg.value >= _price * num, "Ether sent is not correct");

    for (uint256 i = 1; i <= num; i++) {
      _safeMint(msg.sender, supply + i);
      _tokenSupply.increment();
    }
 

    walletCount[msg.sender] += num;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function breed(uint256 _parent1, uint256 _parent2)
    external
    aPigsOwner(_parent1)
    aPigsOwner(_parent2)
  {
    require(_parent1 != _parent2, "Parents must be different");

    boomContract.burn(msg.sender, breedPrice);
    babyPigsContract.mint(msg.sender);
  }

  function walletOfOwner(address owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(owner);
    uint256[] memory tokensId = new uint256[](tokenCount);

    for (uint256 i; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(owner, i);
    }

    return tokensId;
  }

  function setmaxAmount(uint256 _newMax) public onlyOwner {
    maxAmount = _newMax;
    }
  
  
  
  function setRootHash(bytes32 rootHash) public onlyOwner {
    _rootHash = rootHash;
    }
    
  function giveAway(address _to, uint256 _amount) external onlyOwner {
    require(_amount <= _reserved, "Exceeds reserved supply");

    uint256 supply = _tokenSupply.current();

    for (uint256 i = 1; i <= _amount; i++) {
      _safeMint(_to, supply + i);
      _tokenSupply.increment();
    }

    _reserved -= _amount;
  }

  function pause(bool state) public onlyOwner {
    paused = state;
  }

  function publicMintPause(bool state) public onlyOwner {
    publicMintPaused = state;
  }

  function setBabyPigsContract(address _babyPigsAddress) public onlyOwner {
    babyPigsContract = BabyPigs(_babyPigsAddress);
  }

  function setBoomContract(address _boomAddress) public onlyOwner {
    boomContract = Boom(_boomAddress);
  }

  function setBreedPrice(uint256 _newPrice) public onlyOwner {
    breedPrice = _newPrice;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    baseTokenURI = baseURI;
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    if (address(boomContract) != address(0)) {
      boomContract.updateTokens(from, to);
    }

    ERC721.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override {
    if (address(boomContract) != address(0)) {
      boomContract.updateTokens(from, to);
    }

    ERC721.safeTransferFrom(from, to, tokenId, data);
  }

  function withdraw() public onlyOwner {
    require(
      payable(owner()).send(address(this).balance),
      "Withdraw unsuccessful"
    );
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
  {
    string memory _tokenURI = super.tokenURI(tokenId);

    return
      bytes(_tokenURI).length > 0
        ? string(abi.encodePacked(_tokenURI, ".json"))
        : "";
  }
}