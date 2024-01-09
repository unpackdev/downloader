// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract DoWhatManNFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.04 ether; // <-- Mint Cost
  uint256 public maxSupply = 205; // <-- Max Number of NFTs
  uint256 public maxMintAmount = 10;
  bool public paused = true;

  constructor(
    string memory _initBaseURI
  ) ERC721 ("DO WHAT MAN!", "DOWHATMAN") {
    setBaseURI(_initBaseURI);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

   function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused, "mint is not paused");
    require(_mintAmount > 0, "mint amount must be greater than 0");
    require(
        _mintAmount <= maxMintAmount,
        "mint amount must be less than or equal to max mint amount"
    );
    require(supply + _mintAmount <= maxSupply, "not enough supply");

    require(msg.value >= cost * _mintAmount, "not enough ether sent");

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
    for (uint i; i < ownerTokenCount; i++) {
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
      ? string (
        abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)
      ) : "";
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension)
    public
    onlyOwner
  {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public payable onlyOwner {
    // This will payout the owner 100% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success, "Failed to send ether to the owner");
    // =============================================================================
  }
}