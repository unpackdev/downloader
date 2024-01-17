// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721AQueryable.sol";

contract CNPPHelloweenSBT is ERC721AQueryable, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public maxSupply = 100;
  uint256 public maxMintAmount = 1;
  bool public paused = true;

  constructor(
  ) ERC721A("CNPP Helloween SBT", "CNPPF") {
    baseURI = "https://data.cnpphilippines.com/cnppfs/metadata/";
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // external
  function mint(uint256 _mintAmount) external {
    uint256 supply = totalSupply();
    require(!paused, "mint is paused!");
    require(tx.origin == msg.sender,"the caller is another controler");
    require(balanceOf(_msgSenderERC721A()) == 0, "You already have SBT");
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    _safeMint(_msgSenderERC721A(), _mintAmount);
  }

  function burn(uint256 burnTokenId) external {
    require (_msgSenderERC721A() == ownerOf(burnTokenId),"Only the owner can burn");
    _burn(burnTokenId);
  }

  function tokenURI(uint256 tokenId) public view virtual override(IERC721A,ERC721A) returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721AMetadata: URI query for nonexistent token"
    );
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function setmaxMintAmount(uint256 _newmaxMintAmount) external onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setMaxSupply(uint256 _maxSupply) external onlyOwner {
    maxSupply = _maxSupply;
  }
  
  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) external onlyOwner {
    paused = _state;
  }

  //SBT
  function approve(address , uint256 ) public pure override(IERC721A,ERC721A) {
    require(false, "This token is SBT, so this can not approval.");
  }

  function setApprovalForAll(address , bool ) public pure override(IERC721A,ERC721A) {
    require(false, "This token is SBT, so this can not approval.");
  }

  function transferFrom(
    address ,
    address ,
    uint256 
  ) public pure  override(IERC721A,ERC721A) {
    require(false, "This token is SBT, so this can not transfer.");
  }

  //start token id
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  } 
}