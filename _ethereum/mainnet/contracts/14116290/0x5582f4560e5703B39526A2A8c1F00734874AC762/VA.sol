// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Voxel_Ape is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.35 ether;
  uint256 public maxSupply = 9898;
  bool public paused = false;
  bool public revealed = false;
  mapping(address => uint256) public addressMintedBalance;
  address payable private devguy = payable(0x70867141d70b948420b2cB380b36424a235875Bc);

  constructor() ERC721("Voxel Ape", "VA") {}

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public mint
  function mint(uint256 _mintAmount) public payable {
    require(!paused, "the mint is paused");
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
        require(msg.value >= cost * _mintAmount, "insufficient funds");
    }
    
    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }

  function minted(address _to, uint256 _mintAmount) public onlyOwner payable {
    require(!paused, "the mint is paused");
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
    
    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[_to]++;
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

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function withdraw() external onlyOwner {
    uint part = address(this).balance / 1000 * 35;
    devguy.transfer(part);
    payable(owner()).transfer(address(this).balance);
  }
}