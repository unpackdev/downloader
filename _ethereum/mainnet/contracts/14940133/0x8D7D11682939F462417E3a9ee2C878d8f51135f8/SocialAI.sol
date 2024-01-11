// SPDX-License-Identifier: NONE

pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract SocialAI is ERC721A, Ownable, ReentrancyGuard {
  string private baseURI = "ipfs://QmTypJGP2QUn8dZ4vHGN9FX5SdvV75rkXHoeHakH8JGghy/";
  uint public reservedAmount = 555;
  uint public constant maxSupply = 5555;

  constructor() ERC721A("SocialAI", "SAI") {}

  //internal
  function _baseURI() internal view virtual override returns(string memory) {
    return baseURI;
  }

  function _startTokenId() internal view virtual override returns(uint256) {
    return 1;
  }

  // public
  function mint() external nonReentrant {
    uint supply = totalSupply();

    require(supply + 1 <= maxSupply - reservedAmount, "mint over");
    require(_numberMinted(msg.sender) == 0, "limited to 1 per wallet - be FAIR, not GREEDY");
    require(msg.sender == tx.origin);

    _safeMint(msg.sender, 1);
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function reserve(address _to, uint _mintAmount) public onlyOwner {
    require(_mintAmount <= reservedAmount);

    reservedAmount -= _mintAmount;
    _safeMint(_to, _mintAmount);
  }

  function withdraw () public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}