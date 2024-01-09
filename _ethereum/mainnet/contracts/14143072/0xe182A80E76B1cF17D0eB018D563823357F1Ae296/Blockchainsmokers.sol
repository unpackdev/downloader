//SPDX-License-Identifier: MIT
//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
/*
 __     __              __          __           __                              __
|  |--.|  |.-----.----.|  |--.----.|  |--.---.-.|__|.-----.-----.--------.-----.|  |--.-----.----.-----.
|  _  ||  ||  _  |  __||    <|  __||     |  _  ||  ||     |__ --|        |  _  ||    <|  -__|   _|__ --|
|_____||__||_____|____||__|__|____||__|__|___._||__||__|__|_____|__|__|__|_____||__|__|_____|__| |_____|
*/

pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract BlockChainSmokers is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI = "ipfs://QmVQGteoXXh29uNEvCJCLS81xkZeeK3iSFpNHSYt9oGRCd/";
  string public baseExtension = ".json";
  uint256 public cost = 0.02 ether;
  uint256 public maxSupply = 2424;
  uint256 public maxMintAmount = 20;
  bool public paused = false;
  // Addresses in the whitelist only pay gas fees, enjoy!
  mapping(address => bool) public whitelisted;

  constructor() ERC721("blockchainsmokers", "BCS") {
    mint(msg.sender, 20);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused, "minting is currently paused");
    require(_mintAmount > 0, "You have to mint at least one blockchainsmoker");
    require(_mintAmount <= maxMintAmount, "You tried to mint more than is authorized");
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
        if(whitelisted[msg.sender] != true) {
          require(msg.value >= cost * _mintAmount);
        }
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
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

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
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
 
 function whitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = true;
  }
 
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}
