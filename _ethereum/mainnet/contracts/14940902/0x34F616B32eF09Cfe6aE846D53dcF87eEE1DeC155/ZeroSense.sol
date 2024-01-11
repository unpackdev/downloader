//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";

import "./console.sol";

contract ZeroSense is ERC721, IERC2981, Ownable, ReentrancyGuard {
  bool public minted = false;
  address public artist;
  address public rockGarden;
  address public collector;
  uint256 public offChainSalePrice;
  uint256 public artistBalance = 0;
  uint256 public rockGardenBalance = 0;
  string public baseURI;

  constructor(
    address _artist,
    address _rockGarden,
    address _collector,
    uint256 _offChainSalePrice
  ) ERC721("ZeroSense", "ZERO") {
    artist = _artist;
    rockGarden = _rockGarden;
    offChainSalePrice = _offChainSalePrice;
    collector = _collector;
  }

  // This shouldn't get called. Putting this here just in case
  receive () external payable {
    artistBalance = artistBalance + msg.value / 2;
    rockGardenBalance = rockGardenBalance + msg.value / 2;
  }

  function withdrawToArtist () public nonReentrant {
    address sender = _msgSender();
    require ((sender == artist || sender == rockGarden), 'Can only be called by artist or Rock Garden');
    require (artistBalance > 0, 'Artist has no balance');
    uint256 balance = artistBalance;
    artistBalance = 0;
    payable(artist).transfer(balance);
  }

  function withdrawToRockGarden () public nonReentrant {
    address sender = _msgSender();
    require (sender == rockGarden, 'Can only be called by RockGarden');
    require (rockGardenBalance > 0, 'Rock Garden has no balance');
    uint256 balance = rockGardenBalance;
    rockGardenBalance = 0;
    payable(rockGarden).transfer(balance);
  }

  function mint (string memory baseURI_) public payable nonReentrant {
    require(minted == false, "Already minted");
    require(msg.value == offChainSalePrice, "Incorrect payable amount");

    // Split the price between rockGarden and artist
    rockGardenBalance = rockGardenBalance + msg.value / 2;
    artistBalance = artistBalance + msg.value / 2;
    minted = true;

    // Generate Token and transfer to collector
    _safeMint(collector, 0);
    setBaseURI(baseURI_);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI (string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  // ERC165
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  // IERC2981
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address, uint256) {
    _tokenId; // silence solc warning

    return (artist, _salePrice / 10);
  }
}
