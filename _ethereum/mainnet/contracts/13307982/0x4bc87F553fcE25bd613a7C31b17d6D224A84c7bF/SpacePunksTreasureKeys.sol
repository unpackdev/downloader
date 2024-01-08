// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract SpacePunksTreasureKeys is ERC1155, Ownable {
  using Strings for uint256;

  mapping(uint256 => bool) private _availableTypes;
  string private baseURI;

  event AddType(address indexed burner, uint256 indexed typeId);
  event RemoveType(uint256 indexed typeId);
  event SetBaseURI(string _baseURI);

  constructor(string memory _baseURI) ERC1155(_baseURI) {
    baseURI = _baseURI;
    emit SetBaseURI(baseURI);
  }

  function mintBatch(uint256[] memory ids, uint256[] memory amounts) external onlyOwner {
    _mintBatch(owner(), ids, amounts, "");
  }

  function addTypeForBurner(address burner, uint256 typeId) external onlyOwner {
    _availableTypes[typeId] = true;
    emit AddType(burner, typeId);
  }

  function removeType(uint256 typeId) external onlyOwner {
    _availableTypes[typeId] = false;
    emit RemoveType(typeId);
  }

  function burnKeyForAddress(uint256 typeId, address burnTokenAddress) external {
    require(_availableTypes[typeId], "SpacePunksTreasureKeys: unavailable token type");
    _burn(burnTokenAddress, typeId, 1);
  }

  function getBaseUri() external view onlyOwner returns (string memory) {
    return baseURI;
  }

  function setBaseUri(string memory _baseURI) external onlyOwner {
    baseURI = _baseURI;
    emit SetBaseURI(baseURI);
  }

  function uri(uint256 typeId) public view override returns (string memory) {
    return bytes(baseURI).length > 0
      ? string(abi.encodePacked(baseURI, typeId.toString()))
      : baseURI;
  }
}
