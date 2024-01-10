// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";

contract GramatikOfficial is ERC721Enumerable, Ownable, ReentrancyGuard {
  string BASE_URI;

  constructor(string memory baseUri) ERC721("Gramatik Official", "GM") {
    BASE_URI = baseUri;
    minters[msg.sender] = true;
  }

  function setBaseUri(string memory baseUri) public onlyOwner {
    BASE_URI = baseUri;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return BASE_URI;
  }

  mapping(address => bool) public minters;

  function updateMinter(address minter, bool val) public onlyOwner {
    minters[minter] = val;
  }

  function _mint(address to) internal {
    uint256 tokenId = ++currentId;
    _safeMint(to, tokenId);
  }

  uint256 currentId;

  function mintToMany(address[] memory to, uint256[] memory amount) public {
    require(minters[msg.sender] == true, "Not minter");
    require(to.length == amount.length);

    for (uint256 i = 0; i < to.length; i++) {
      mintManyToOne(to[i], amount[i]);
    }
  }

  function mintManyToOne(address to, uint256 amount) public {
    require(minters[msg.sender] == true, "Not minter");
    for (uint256 i = 0; i < amount; i++) {
      _mint(to);
    }
  }
}
