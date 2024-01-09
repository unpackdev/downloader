// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";

// @author rollauver.eth

contract FuegoUniques is ERC721A, Ownable {
  string public _baseTokenURI;
  uint256 public _maxSupply;

  constructor(
    string memory name,
    string memory symbol,
    string memory baseTokenURI,
    uint256 maxSupply
  ) ERC721A(name, symbol, maxSupply) {
    _baseTokenURI = baseTokenURI;
    _maxSupply = maxSupply;
  }

  function setBaseUri(
    string memory baseUri
  ) external onlyOwner {
    _baseTokenURI = baseUri;
  }

  function _baseURI() override internal view virtual returns (string memory) {
    return string(
      abi.encodePacked(
        _baseTokenURI,
        Strings.toHexString(uint256(uint160(address(this))), 20),
        '/'
      )
    );
  }

  function mint(address to, uint256 count) external payable onlyOwner {
    ensureMintConditions(count);

    _safeMint(to, count);
  }

  function ensureMintConditions(uint256 count) internal view {
    require(totalSupply() + count <= _maxSupply, "BASE_COLLECTION/EXCEEDS_MAX_SUPPLY");
  }
}
