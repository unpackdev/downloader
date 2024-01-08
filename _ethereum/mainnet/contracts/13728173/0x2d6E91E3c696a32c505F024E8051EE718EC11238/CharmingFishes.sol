// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

import "./IFearlessShrimps.sol";

contract CharmingFishes is ERC721Enumerable, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;
  
  Counters.Counter public _saleCounter;
  Counters.Counter public _evolveCounter;
  Counters.Counter public _totalSupply;

  IFearlessShrimps public FS;

  address payable public treasury;
  address payable public developer;

  string public baseURI;
  string public notRevealedUri;

  uint256 public cost = 0.8 ether;
  uint256 public maxSaleSupply = 500;
  uint256 public maxEvolveSupply = 2000;
  uint256 public maxMintPerTxn = 10;
  uint256 public maxMintPerWallet = 10; 

  uint256 public publicSaleStartTime = 1638730800; // 1900 UTC 5th December

  bool public paused = false;
  bool public revealed = false;
  bool public publicSaleOpen = false;

  mapping(address => uint256) public addressToMintedAmount;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    address _treasury,
    address _developer,
    address _fs
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    treasury = payable(_treasury);
    developer = payable(_developer);
    FS = IFearlessShrimps(_fs);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function publicMint(uint256 _mintAmount) public payable {
    uint256 saleCount = _saleCounter.current();
    require(!paused);
    require(isPublicSaleOpen() || publicSaleOpen, "RRC: Public Sale is not open");
    require(saleCount + _mintAmount <= maxSaleSupply, "RRC: Total mint amount exceeded for sale");
    require(_mintAmount > 0, "RRC: Please mint atleast one NFT");
    require(_mintAmount <= maxMintPerTxn, "RRC: You can only mint up to 10 per txn");
    require(msg.value == cost * _mintAmount,"RRC: not enough ether sent for mint amount");
    require(addressToMintedAmount[msg.sender] + _mintAmount <= maxMintPerWallet, "RRC: Exceeded max mints allowed per wallet");

    (bool successT, ) = treasury.call{ value: (msg.value*91)/100 }(""); // forward amount to treasury wallet
    require(successT, "RRC: not able to forward msg value to treasury");

    (bool successD, ) = developer.call{ value: (msg.value*9)/100 }(""); // forward amount to developer wallet
    require(successD, "RRC: not able to forward msg value to developer");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _totalSupply.increment();
      _saleCounter.increment();
      addressToMintedAmount[msg.sender]++;
      _safeMint(msg.sender, _totalSupply.current()); 
    }
  }

  function evolve(uint256 _evolveAmount, uint256[] memory tokenIds) public payable {
    uint256 evolveCount = _evolveCounter.current();
    require(!paused);
    require(tokenIds.length == 5 *_evolveAmount, "Please select the right amount of shrimps");
    require(areOwned(tokenIds));
    require(evolveCount + _evolveAmount <= maxEvolveSupply, "RRC: Total evolve amount exceeded for sale");
    require(_evolveAmount > 0, "RRC: Please evolve atleast one NFT");
    
    for (uint256 i = 1; i <= _evolveAmount; i++) {
      // Burn first 5 from tokenIds list
      for (uint256 j = 0; j <= 4; j++){
        uint256 indexToBurn = (5*(i-1))+j; 
        FS.burn(tokenIds[indexToBurn]);
      }
      _totalSupply.increment();
      _evolveCounter.increment();
      _safeMint(msg.sender, _totalSupply.current());
      
    }
  }

  function areOwned(uint256[] memory tokenIds) public view returns (bool out) {
    out = true;
    for (uint256 i = 0; i < tokenIds.length; i++){
      if (FS.ownerOf(tokenIds[i]) != msg.sender){
        out = false;
      }
    }
  }

  function isPublicSaleOpen() public view returns (bool) {
    return block.timestamp >= publicSaleStartTime;
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
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
        : "";
  }

  function burn(uint256 _tokenId) public {
    require(
      _isApprovedOrOwner(_msgSender(), _tokenId),
      "ERC721: transfer caller is not owner nor approved"
    );
    _burn(_tokenId);
  }

  //*** OnlyOwner Functions ***//
  function reveal() public onlyOwner() {
      revealed = true;
  }

  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintPerWallet = _newmaxMintAmount;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }

  function setPublicSaleOpen(bool _publicSaleOpen) public onlyOwner {
    publicSaleOpen = _publicSaleOpen;
  }

  function setPublicSaleStartTime(uint256 _publicSaleStartTime) public onlyOwner {
    publicSaleStartTime = _publicSaleStartTime;
  }

}
