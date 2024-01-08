//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract KrazyKookingToken is ERC721Enumerable, Ownable  {
  string _baseTokenURI = "ipfs://QmZVR2mAhQqsjNMvF5pWVZMGcG1tM7iaYTaDu4XMqnT98r/";

  bool private paused = true;
  uint256 public constant MAX_CARDS = 6000;
  uint256 public RESERVED_CARDS = 100;
  uint8 private MAX_CARDS_PER_OWNER = 10;
  uint256 private PRICE = 0.035 ether;

  constructor() ERC721("KrazyKooking", "CRKOOK") {}

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }


  function _mintCard(address to, uint256 id) internal virtual {
    _safeMint(to, id);
  }

  function price(uint256 _count) public view returns (uint256) {
    return SafeMath.mul(_count, PRICE);
  }

  function setBaseTokenURL(string memory url) public onlyOwner {
    _baseTokenURI = url;
  }

  function mintCard(address to, uint256 count) public payable {
    require(!paused, "Pause");
    require(count <= MAX_CARDS_PER_OWNER, "Yo can't mint more than 10");
    require(msg.value >= price(count), "Value below price");
    require(totalSupply() + count <= MAX_CARDS, "Max limit");
    require(totalSupply() < MAX_CARDS, "Sale end");
    for (uint256 i = 0; i < count; i++) {
      _mintCard(to, totalSupply());
    }
  }
  

  function reserveCards(address to, uint256 count) public onlyOwner {
    require(RESERVED_CARDS > 0, "Reach limit");
    require(count <= RESERVED_CARDS, "Exceeds max limit");
    for (uint256 i = 0; i < count; i++) {
      _mintCard(to, totalSupply());
    }
    RESERVED_CARDS = SafeMath.sub(RESERVED_CARDS, count);
  }

  function startDrop() public onlyOwner {
    paused = false;
  }

  function stopDrop() public onlyOwner {
    paused = true;
  }

  function withdrawAll() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}
