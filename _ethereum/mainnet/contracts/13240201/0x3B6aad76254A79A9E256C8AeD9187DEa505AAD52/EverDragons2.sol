// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Author: Francesco Sullo <francesco@sullo.co>
// EverDragons2, https://everdragons2.com

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IEverDragons2.sol";
import "./DragonsMaster.sol";

contract EverDragons2 is IEverDragons2, ERC721, ERC721Enumerable, Ownable {
  using Address for address;
  address public manager;

  string private _uri = "https://everdragons2.com/metadata/ed2/";
  bool private _mintEnded;

  modifier onlyManager() {
    require(manager != address(0) && _msgSender() == manager, "Forbidden");
    _;
  }

  modifier canMint() {
    require(!_mintEnded, "Minting ended");
    _;
  }

  constructor() ERC721("EverDragons2", "ED2") {
    _mint(msg.sender, 10001);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function setManager(address manager_) external override onlyOwner canMint {
    require(manager_ != address(0), "Manager cannot be 0x0");
    manager = manager_;
  }

  function mint(address recipient, uint256[] memory tokenIds) external override onlyManager canMint {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _mint(recipient, tokenIds[i]);
    }
  }

  function mint(address[] memory recipients, uint256[] memory tokenIds) external override onlyManager canMint {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _mint(recipients[i], tokenIds[i]);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _uri;
  }

  function updateBaseURI(string memory uri) external override onlyOwner {
    // this is mostly an emergency command
    _uri = uri;
  }

  function endMinting() external override onlyOwner {
    _mintEnded = true;
  }
}
