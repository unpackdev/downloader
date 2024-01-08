// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract GangstaHamsta is ERC721Enumerable, Ownable, ReentrancyGuard {
  uint256 private constant MAX_GANGSTA_HAMSTA = 8888;
  uint256 private constant GANGSTA_HAMSTA_PER_TX = 50;
  uint256 private constant GANGSTA_HAMSTA_PRICE = 0.01 ether;

  string public GANGSTA_HAMSTA_PROVENANCE;
  bool private _isPublicSaleActive = false;
  string private _baseTokenURI;

  uint256 CHARITY_SHARES = 5;
  uint256 DEV_SHARES = 50;
  uint256 ARTIST_SHARES = 45;
  address ARTIST_ADDRESS = 0x116d334D852D6e685E2CEb875f1B1B8bAF5d781f;
  address CHARITY_ADDRESS = 0x354383657f82AD49C303fF4E562A32f3491C70D7; // she's the first

  uint256 public BOSS_GANGSTA_HAMSTA = 0;
  bool public isBossSelected = false;

  constructor(
    string memory name,
    string memory symbol,
    string memory baseTokenURI
  ) ERC721(name, symbol) {
    _baseTokenURI = baseTokenURI;
  }

  function withdraw() public onlyOwner {
    uint256 totalBalance = address(this).balance;
    uint256 charityShare = (totalBalance * CHARITY_SHARES) / 100;
    uint256 artistShare = (totalBalance * ARTIST_SHARES) / 100;
    uint256 devShare = (totalBalance * DEV_SHARES) / 100;
    require(
      payable(CHARITY_ADDRESS).send(charityShare),
      "Unable to send funds to charity."
    );
    require(
      payable(ARTIST_ADDRESS).send(artistShare),
      "Unable to send funds to Artist."
    );
    require(
      payable(msg.sender).send(devShare),
      "Unable to send funds to Onwer."
    );
    assert(address(this).balance == 0);
  }

  function togglePublicSale() external onlyOwner {
    _isPublicSaleActive = !_isPublicSaleActive;
  }

  function isPublicSaleActive() external view returns (bool status) {
    return _isPublicSaleActive;
  }


  function selectBossGangsta() public onlyOwner {
    require(isBossSelected == false, "Boss Gangsta Hamsta already minted and selected"); 
    uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % (MAX_GANGSTA_HAMSTA - 1);
    randomnumber = randomnumber + 200; 
      if (randomnumber >= 200 && randomnumber <= MAX_GANGSTA_HAMSTA){
          BOSS_GANGSTA_HAMSTA =  randomnumber;
          isBossSelected = true; // we can only Gangsta Hamsta Boss once
      }
  } 

  function getBossGangstaHamsta() public view returns (uint256){ 
    require(isBossSelected == true, "Boss Gangsta Hamsta is not yet selected"); 
    return BOSS_GANGSTA_HAMSTA;
  }

  /*
   * A SHA256 hash representing all 8888 GANGSTA_HAMSTA. Will be set once all 8888 are out for blood.
   */
  function setProvenanceHash(string memory provenanceHash) public onlyOwner {
    GANGSTA_HAMSTA_PROVENANCE = provenanceHash;
  }

  function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
    _baseTokenURI = baseTokenURI;
  }

  function mintPublic(uint256 amount) external payable nonReentrant() {
    require(_isPublicSaleActive, "Public sale is not active");
    require(
      amount > 0 && amount <= GANGSTA_HAMSTA_PER_TX,
      "You can't mint that many GANGSTA_HAMSTA"
    );
    require(
      totalSupply() + amount <= MAX_GANGSTA_HAMSTA,
      "Mint would exceed max supply of GANGSTA_HAMSTA"
    );
    require(
      msg.value == amount * GANGSTA_HAMSTA_PRICE,
      "You didn't send the right amount of eth"
    );
    _mintMultiple(msg.sender, amount);
  }

  /*
   * Sets aside some GANGSTA_HAMSTA for the dev team, used for competitions, giveaways and mods memberships
   */
  function reserve(uint256 amount) external onlyOwner {
    _mintMultiple(msg.sender, amount);
  }

  function _mintMultiple(address owner, uint256 amount) private {
    for (uint256 i = 0; i < amount; i++) {
      uint256 tokenId = totalSupply();
      _safeMint(owner, tokenId);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  receive() external payable {}
}
