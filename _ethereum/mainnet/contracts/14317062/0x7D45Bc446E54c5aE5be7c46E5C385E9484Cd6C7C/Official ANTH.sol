// SPDX-License-Identifier: MIT

// Amended by The Apex Meta Group, A Delaware C Corporation
/**
    !The Apez N The Hood NFT Collection!

    This contract is the Official Apez N The Hood smart
    contract for a collection of 10,000 one of one NFTs
    that have in-game functionality within the AMG Metahood,
    a one of a kind blockchain gaming experience.  
    This functionality includes but is not limited to a unique
    in-game avatar and God Mode (Developer mode) capabilities.
    The roadmap consist of 7 giveaways that would be triggered
    upon reaching the described ANTH NFT sales milestones. The
    Grand Prize becomes gaurenteed when 20% of the supply has
    been purchased.  In the event the supply is "burned" by
    community demand, the community understands and agrees that
    any giveaways that have not been triggered will also be
    burned.  
    The community owns 100% of the 10% royalty that has been
    assigned to this collection. There are different events that
    would allow holders of this NFT to partipate in exclusive
    events.
    By purchasing this ANTH NFT that is offered by the Apex Meta
    Group, a fully doxxed Delaware C Corporation, you agree to the
    terms and conditions set forth in this smart contract as well
    the terms and conditions set forth on the ANTH website.
    For more information, please visit https://apeznthehood.io.
*/

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract ApezNTheHood is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.15 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmountPerTx = 100;

  bool public paused = true;
  bool public revealed = false;

  bool public presale = true; 
  mapping(address => bool) public whitelisted;
  uint256 public maxPresaleMintAmount = 300;

  constructor() ERC721("Apez N The Hood", "ANTH") {
    setHiddenMetadataUri("ipfs://QmQdcUJKZtzeSZCc2K51cJorbagGnN5rKvYvXLuREeKagB/hidden.json");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "That's not gonna work!");
    require(supply.current() + _mintAmount <= maxSupply, "You can't eat all the bananas at once!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, "This contract has been paused!");
    require(msg.value >= cost * _mintAmount, "You don't have enough Ethereum to make that happen!");

      if (presale) {
        if ( !isInWhiteList(msg.sender))  {
            revert("Buyer ain't on the list!");
        }
        if ( balanceOf(msg.sender)+_mintAmount > maxPresaleMintAmount)
            revert("Buyer is tryna get more the they are authorized for!");
    } 

    _mintLoop(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxPresaleMintAmount(uint256 _max) public onlyOwner {
      maxPresaleMintAmount = _max;
  }

  function addToWhiteList(address _addr) public onlyOwner {
      whitelisted[_addr] = true;
  }

  function addArrayToWhiteList(address[] memory _addrs) public onlyOwner {
      for (uint256 i=0;i< _addrs.length;i++)
          whitelisted[_addrs[i]] = true; 
  }

  function removeFromWhiteList(address _addr) public onlyOwner {
      whitelisted[_addr] = false;
  }

  function isInWhiteList(address _addr) private view returns (bool) {
      return whitelisted[_addr]  || _addr == owner();
  }

   function setPresale(bool _state) public onlyOwner {
      presale = _state;
  }
  
  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}