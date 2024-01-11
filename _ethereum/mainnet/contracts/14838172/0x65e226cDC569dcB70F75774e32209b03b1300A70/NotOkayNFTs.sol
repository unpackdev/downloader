// SPDX-License-Identifier: MIT

//  _____       ____  _  __   ____  ____  _      _____  ____  ____  ____  _____  ____ 
// /    /_/||\_/   _\/ |/ /  /   _\/  _ \/ \  /|/__ __\/  __\/  _ \/   _\/__ __\/ ___\
// |  __\\    /|  /  |   /   |  /  | / \|| |\ ||  / \  |  \/|| / \||  /    / \  |    \
// | |   /    \|  \__|   \   |  \__| \_/|| | \||  | |  |    /| |-|||  \__  | |  \___ |
// \_/    \||/ \____/\_|\_\  \____/\____/\_/  \|  \_/  \_/\_\\_/ \|\____/  \_/  \____/
//                                                                                    

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract NotOkayNFTs is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.00 ether;
  uint256 public maxSupply = 5000;
  uint256 public maxMintAmount = 1;
  mapping(address => uint256) public mintedWallets;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(_mintAmount > 0);
    require(mintedWallets[msg.sender] < 1, 'Max one mint per wallet');
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    mintedWallets[msg.sender]++;

    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount);
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
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
  
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
 
  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}