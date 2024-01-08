// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./APigs.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract BabyPigs is ERC721Enumerable, Ownable {
  string public baseTokenURI;

  APigs private aPigsContract;

  modifier onlyAPigsContract() {
    require(_msgSender() == address(aPigsContract), "Not aPigs address");
    _;
  }

  constructor(string memory baseURI) ERC721("BabyPigs", "BABYPIGS") {
    setBaseURI(baseURI);
  }

  function mint(address _to) public onlyAPigsContract {
    uint256 supply = totalSupply();

    require(supply + 1 <= 6666, "Exceeds maximum supply");

    _safeMint(_to, totalSupply() + 1);
  }

  function walletOfOwner(address owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(owner);
    uint256[] memory tokensId = new uint256[](tokenCount);

    for (uint256 i; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(owner, i);
    }

    return tokensId;
  }

  function setAPigsContract(address _aPigsAddress) public onlyOwner {
    aPigsContract = APigs(_aPigsAddress);
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    baseTokenURI = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
  {
    string memory _tokenURI = super.tokenURI(tokenId);

    return
      bytes(_tokenURI).length > 0
        ? string(abi.encodePacked(_tokenURI, ".json"))
        : "";
  }
}