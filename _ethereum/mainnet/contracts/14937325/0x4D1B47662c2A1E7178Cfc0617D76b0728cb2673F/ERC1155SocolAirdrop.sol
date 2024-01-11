// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./StringsLib.sol";

contract ERC1155SocolAirdrop is ERC1155, Ownable {
  using StringsLib for uint256;

  string private _baseURI;
  string public name;
  string public symbol;

  constructor(
    string memory baseURI,
    string memory _name,
    string memory _symbol,
    address[] memory users,
    uint256[] memory ids,
    bytes memory data
  ) ERC1155("") {
    _baseURI = baseURI;
    name = _name;
    symbol = _symbol;

    uint256 amount = users.length;

    for (uint256 i = 0; i < amount; i++) {
      uint256 mintAmount = 1;
      _mint(users[i], ids[i], mintAmount, data);
    }
  }

  function mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public onlyOwner {
    _mint(to, id, amount, data);
  }

  function mintBatch(
    address to,
    uint256[] calldata amounts,
    uint256[] calldata ids,
    bytes memory data
  ) public onlyOwner {
    _mintBatch(to, ids, amounts, data);
  }

  function uri(uint256 _id) public view override returns (string memory) {
    return string(abi.encodePacked(_baseURI, _id.toString(), ".json"));
  }

  function setBaseURI(string memory newBaseURI) public onlyOwner {
    _baseURI = newBaseURI;
  }
}
