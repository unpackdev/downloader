//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract BabyBallerWhaleEth is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string uriPrefix = "";
  string public uriSuffix = ".json";
  
  uint256 public cost = 0.04 ether;
  uint256 public maxSupply = 3000;
  uint256[] public mintedTokens;

  bool public paused = false;
  bool public firstStage = true;

  address[] private whitelistedAddresses;

  constructor(address _initOwner, string memory _initURI) ERC721("BabyBallerWhaleEth", "BBWE") {
    setUriPrefix(_initURI);
    _safeMint(_initOwner, 1);
    supply.increment();
    mintedTokens.push(1);
    transferOwnership(_initOwner);
  }

  modifier mintCompliance() {
    require(supply.current() + 1 <= maxSupply, "Max supply exceeded!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function getCost() public view returns (uint256) {
    return cost;
  }

  function getMintedTokens() public view returns (uint256[] memory) {
    return mintedTokens;
  }

  function mintPaid(uint256 _tokenID) public payable mintCompliance() {
    require(!paused, "The contract is paused!");
    require(msg.value >= cost , "Insufficient funds!");

    if (firstStage) {
        require(isAddressWhitelisted(msg.sender), "Not on the whitelist!");
    }

    _safeMint(msg.sender, _tokenID);
    supply.increment();
    mintedTokens.push(_tokenID);
  }
  
  function mintForAddress(uint256 _tokenID, address _receiver) public mintCompliance() onlyOwner {
    _safeMint(_receiver, _tokenID);
    supply.increment();
    mintedTokens.push(_tokenID);
  }

  function isAddressWhitelisted(address _user) private view returns (bool) {
    uint i = 0;
    while (i < whitelistedAddresses.length) {
        if(whitelistedAddresses[i] == _user) {
            return true;
        }
    i++;
    }
    return false;
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

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setWhitelist(address[] calldata _addressArray) public onlyOwner {
      delete whitelistedAddresses;
      whitelistedAddresses = _addressArray;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setFirstStage(bool _state) public onlyOwner {
    firstStage = _state;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}