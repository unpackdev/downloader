// //SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "./console.sol";

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract Calaveritas is ERC721, ERC721URIStorage, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  string public baseURI = "";
  string public baseExtension = ".json";
  bool public paused = false;

  uint256 public price = 0.025 ether;
  uint256 public maxSupply = 1111;
  uint256 public maxMintAmount = 5;

  mapping(address => bool) public allowlisted;

  address a1 = 0x2E5ceD7Ef989D62e3E5076011878927a185466f9;
  address a2 = 0x81d817e61FAfa5Fc2A6B380d95D3714a68D59709;

  Counters.Counter private _tokenIdCounter;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);

    mintCLVRA(a1, 15);
    mintCLVRA(a2, 15);
  }

  function mintCLVRA(address _recipient, uint256 _mintAmount) public payable {
    uint256 _supply = _tokenIdCounter.current();
    require(!paused, "minting is paused");
    require(_mintAmount > 0, "mint amount is not nonzero");
    require(
      _supply + _mintAmount <= maxSupply,
      "tried minting more than what is available. only a few left!"
    );

    if (msg.sender != owner()) {
      require(
      _mintAmount <= maxMintAmount,
      "cannot mint more than the maxMintAmount"
    );
      if (allowlisted[msg.sender] != true) {
        require(
          msg.value >= price * _mintAmount,
          "cannot send less eth than necessary"
        );
      }
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_recipient, _supply + i);
      _tokenIdCounter.increment();
    }

    if (_supply + _mintAmount == maxSupply) {
      withdrawAll();
    }
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory newBaseURI) public onlyOwner {
    baseURI = newBaseURI;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)
        )
        : "";
  }

  function setNewMaxSupply(uint256 newMaxSupply) public onlyOwner {
    maxSupply = newMaxSupply;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function allowlistUser(address _user) public onlyOwner {
    allowlisted[_user] = true;
  }

  function removeAllowlistUser(address _user) public onlyOwner {
    allowlisted[_user] = false;
  }

  function withdrawAll() public payable onlyOwner {
    uint256 _each = address(this).balance / 2;
    require(payable(a1).send(_each));
    require(payable(a2).send(_each));
  }
}
