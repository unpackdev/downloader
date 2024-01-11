// SPDX-License-Identifier: MIT
// www.thecreatiiives.com

pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract SoberPandaCrew is Ownable, ERC721A {
  using Strings for uint256;

  string public uriPrefix = "ipfs://QmevjzRsn5bvMA467LvktbvSqCzxEKGPpaDxiEy2gSuRSG/";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.01 ether;
  uint256 public maxSupply = 8888;
  uint256 public wlSupply = 1111;
  uint256 public maxMintAmountPerTx = 50;
  uint256 public maxMintAmount = 1;

  bool public paused = true;
  bool public revealed = true;
  bool public freeSupply = true;

  address public partnerone = 0xB80e20A02498D3f5e3f0FFE342DF75c97a4667cB;
  address public partnertwo = 0x23BAD9e51C5e088A0f87B37Bd824842141e5e2D5;
  address public partnerthree = 0x2cd2cB2205f44a3cEAB2135A1c0E852bC5702206;
  address public partnerfour = 0x0528C9f5Ca1ED8264C23C70F6159ed83f791e506;
  address public partnerfive = 0xf3638f04432BF94C7Df0CE0620a0D3431fD266A5;
  address public partnersix = 0x73cD189BB1e556Cf222724694e91632bb89f182a;
  address public partnerseven = 0x75f9D6DE31a2BEc2222F51e3EA6F2b5b8694D49a;
  address public partnereight = 0xe077Cd760fcddf223c4e00a7E9C0A5f86E2a2B90;
  address public developer = 0xCB78F1E71440Adfb4Adad98e33C821A70E2df6f0;

  mapping(address => uint256) public allowlist;

  constructor() ERC721A("Sober Panda Crew", "SPC")  {
    setHiddenMetadataUri("");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(!paused, "The contract is paused!");
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    if (!freeSupply) {
      require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    } else {
      require(totalSupply() + _mintAmount <= wlSupply, "Max wl supply exceeded!");
      require(maxMintAmount >= allowlist[msg.sender] + _mintAmount, "not eligible for allowlist mint");
      allowlist[msg.sender] = allowlist[msg.sender] + _mintAmount;
    }

    _safeMint(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    for (uint256 i = 0; i < _mintAmount; i++) {
      _safeMint(_receiver, 1);
    }
  }

  function isAllowed(address _address) public view returns (uint)  {
    return allowlist[_address];
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

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
    maxMintAmount = _maxMintAmount;
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

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setFreeSupply(bool _freeSupply) public onlyOwner {
    freeSupply = _freeSupply;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setPartners(
    address _one,
    address _two,
    address _three,
    address _four,
    address _five,
    address _six,
    address _seven,
    address _eight,
    address _dev
  ) public onlyOwner {
    partnerone = _one;
    partnertwo = _two;
    partnerthree = _three;
    partnerfour = _four;
    partnerfive = _five;
    partnersix = _six;
    partnerseven = _seven;
    partnereight = _eight;
    developer = _dev;
  }

  function withdraw() public onlyOwner {
    (bool paro, ) = payable(partnerone).call{value: address(this).balance * 40 / 100}("");
    require(paro);
    (bool part, ) = payable(partnertwo).call{value: address(this).balance * 75 / 1000}("");
    require(part);
    (bool parth, ) = payable(partnerthree).call{value: address(this).balance * 75 / 1000}("");
    require(parth);
    (bool parf, ) = payable(partnerfour).call{value: address(this).balance * 75 / 1000}("");
    require(parf);
    (bool parfi, ) = payable(partnerfive).call{value: address(this).balance * 75 / 1000}("");
    require(parfi);
    (bool pars, ) = payable(partnersix).call{value: address(this).balance * 75 / 1000}("");
    require(pars);
    (bool parse, ) = payable(partnerseven).call{value: address(this).balance * 75 / 1000}("");
    require(parse);
    (bool pare, ) = payable(partnereight).call{value: address(this).balance * 75 / 1000}("");
    require(pare);
    (bool os, ) = payable(developer).call{value: address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}