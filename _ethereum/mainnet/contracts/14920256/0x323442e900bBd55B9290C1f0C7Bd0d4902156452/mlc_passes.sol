// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract LionPass is ERC721Enumerable, Ownable {
  using Strings for uint256;
  
  string public baseURI;
  string public baseExtension = ".json";

  uint256 public goldSupply = 0;
  uint256 public diamondSupply = 0;

  uint256 public constant GOLD_MAX_SUPPLY = 555;
  uint256 public constant PLATINUM_MAX_SUPPLY = 444;

  uint256 public goldCost = 0.35 ether;
  uint256 public diamondCost = 0.75 ether;

  bool public paused = true;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }

  function mintGold(uint256 _amount) public payable {
    require(!paused, "Minting is currently paused");
    require(_amount > 0, "Amount must be positive integer");
    require(goldSupply + _amount <= GOLD_MAX_SUPPLY, "Insufficient supply remaining");
    require(msg.value >= _amount * goldCost, "Insufficient funds sent");

    for (uint256 i = 1; i <= _amount; i++) {
      _safeMint(msg.sender, goldSupply + i);
    }
    goldSupply += _amount;
  }

  function mintDiamond(uint256 _amount) public payable {
    require(!paused, "Minting is currently paused");
    require(_amount > 0, "Amount must be positive integer");
    require(diamondSupply + _amount <= PLATINUM_MAX_SUPPLY, "Insufficient supply remaining");
    require(msg.value >= _amount * diamondCost, "Insufficient funds sent");

    uint256 offset = GOLD_MAX_SUPPLY + diamondSupply;
    for (uint256 i = 1; i <= _amount; i++) {
      _safeMint(msg.sender, offset + i);
    }
    diamondSupply += _amount;
  }

  function reserveGold(uint256 _amount, address _recipient) public onlyOwner {
    require(_amount > 0, "Amount must be positive integer");
    require(goldSupply + _amount <= GOLD_MAX_SUPPLY, "Insufficient supply remaining");

    for (uint256 i = 1; i <= _amount; i++) {
      _safeMint(_recipient, goldSupply + i);
    }
    goldSupply += _amount;
  }

  function reserveDiamond(uint256 _amount, address _recipient) public onlyOwner {
    require(_amount > 0, "Amount must be positive integer");
    require(diamondSupply + _amount <= PLATINUM_MAX_SUPPLY, "Insufficient supply remaining");

    uint256 offset = GOLD_MAX_SUPPLY + diamondSupply;
    for (uint256 i = 1; i <= _amount; i++) {
      _safeMint(_recipient, offset + i);
    }
    diamondSupply += _amount;
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
    string memory fileName = _tokenId <= GOLD_MAX_SUPPLY ? "gold" : "diamond";
    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, fileName, baseExtension)
        )
        : "";
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setPaused(bool _paused) public onlyOwner {
    paused = _paused;
  }

  function setGoldCost(uint256 _goldCost) public onlyOwner {
    goldCost = _goldCost;
  }

  function setDiamondCost(uint256 _diamondCost) public onlyOwner {
    diamondCost = _diamondCost;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _baseExtension) public onlyOwner {
    baseExtension = _baseExtension;
  }

  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success);
  }
}