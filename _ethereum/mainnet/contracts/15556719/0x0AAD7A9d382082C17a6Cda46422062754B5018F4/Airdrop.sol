// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.16;

import "./Administrable.sol";
import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";

contract Airdrop is ERC1155, ERC1155Supply, ERC1155Burnable, Ownable, Administrable {
  string public name;
  string public symbol;

  constructor(string memory _name, string memory _symbol, string memory _uri) ERC1155(_uri) {
    _setURI(_uri);
    name = _name;
    symbol = _symbol;
  }

  function setURI(string memory _uri) external onlyOwner {
    _setURI(_uri);
  }

  function airdropSingle(uint256 _tokenID, address[] calldata _addresses) external onlyOperatorsAndOwner {
    for (uint256 i = 0; i < _addresses.length;) {
      _mint(_addresses[i], _tokenID, 1, "");
      unchecked { ++i; }
    }
  }

  function airdropMultiple(uint256 _tokenID, address[] calldata _addresses, uint256[] calldata _amounts) external onlyOperatorsAndOwner {
    for (uint256 i = 0; i < _addresses.length;) {
      _mint(_addresses[i], _tokenID, _amounts[i], "");
      unchecked { ++i; }
    }
  }

  function batchMint(address _address, uint256[] calldata _tokenIDs, uint256[] calldata _amounts) external onlyOperatorsAndOwner {
    _mintBatch(_address, _tokenIDs, _amounts, "");
  }

  function batchMintMultiple(address[] calldata _addresses, uint256[] calldata _tokenIDs, uint256[] calldata _amounts) external onlyOperatorsAndOwner {
    for (uint256 i = 0; i < _addresses.length;) {
      _mintBatch(_addresses[i], _tokenIDs, _amounts, "");
      unchecked { ++i; }
    }
  }

  function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControlEnumerable) returns (bool) {
    return
      interfaceId == type(IERC1155).interfaceId ||
      interfaceId == type(IERC1155MetadataURI).interfaceId ||
      super.supportsInterface(interfaceId);
  }
}
