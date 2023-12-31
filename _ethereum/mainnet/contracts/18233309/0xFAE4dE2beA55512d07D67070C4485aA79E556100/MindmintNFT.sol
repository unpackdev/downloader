// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ERC1155PresetMinter.sol";

contract MindmintNFT is ERC1155PresetMinter, ReentrancyGuard {
  using Strings for uint256;

  string private _name;
  string private _symbol;
  uint256 maxSupply = 50_000;
  string public uriPrefix;
  string public uriSuffix = '.json';

  constructor(
    string memory uri_,
    string memory name_,
    string memory symbol_
  ) ERC1155PresetMinter('') {
    _name = name_;
    _symbol = symbol_;
    uriPrefix = uri_;
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function safeTransfer(address to, uint256 id, uint256 amount) public virtual {
    return safeTransferFrom(_msgSender(), to, id, amount, '');
  }

  function safeBatchTransfer(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual {
    return safeBatchTransferFrom(_msgSender(), to, ids, amounts, data);
  }

  function mintBatch(
    address[] memory to,
    uint256[][] memory ids,
    uint256[][] memory amounts,
    bytes memory data
  ) public virtual onlyOwner {
    for (uint i = 0; i < to.length; i++) {
      _mintBatch(to[i], ids[i], amounts[i], data);
    }
  }

  function mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual override onlyOwner {
    require(totalSupply() + amount <= maxSupply, 'Max supply exceeded!');
    _mint(to, id, amount, data);
  }

  function mintAll(
    uint256 _amount,
    uint256 _fromID,
    uint256 _toID
  ) public onlyOwner {
    for (uint256 i = _fromID; i < _toID; i++) {
      _mint(_msgSender(), i, _amount, '');
    }
  }

  function uri(uint256 _tokenID) public view override returns (string memory) {
    require(exists(_tokenID), 'URI query for nonexistent token');
    string memory currentBaseURI = _baseURI();
    return
      string(abi.encodePacked(currentBaseURI, _tokenID.toString(), uriSuffix));
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function _baseURI() internal view returns (string memory) {
    return uriPrefix;
  }
}
