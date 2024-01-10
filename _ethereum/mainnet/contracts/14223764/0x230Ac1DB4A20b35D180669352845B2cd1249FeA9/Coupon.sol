// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract BirthdayCoupon is ERC721, Ownable {
  string public baseTokenURI = "https://storage.googleapis.com/linda-birthday/";

  uint256 public uses = 0;

  event Use(uint256 remainder);

  constructor() ERC721("BirthdayCoupon", "PULI") {}

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, Strings.toString(3 - uses), ".json"))
        : "";
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    baseTokenURI = baseURI;
  }

  function mint(address _to, uint256 _tokenId) public {
    _safeMint(_to, _tokenId);
  }

  function use() public {
    require(uses < 4, "Coupon all used up sadge");
    uses = uses + 1;
    emit Use(uses);
  }
}
