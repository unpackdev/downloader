pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./ERC1155PresetMinterPauser.sol";
import "./console.sol";

contract BaseMonaTokens is ERC1155PresetMinterPauser {
  event RefreshMetadata(uint[] ids, string[] uris);

  mapping(uint256 => address) public tokenOwner;
  string internal uriPrefix;
  string public contractURI;

  constructor() ERC1155PresetMinterPauser("") { }

  function setUriPrefix(string memory _uri) public {
    _requireAdminRole();
    uriPrefix = _uri;
  }

  function uri(uint _id) public view override returns (string memory) {
    return string(abi.encodePacked(uriPrefix, Strings.toString(_id), ".json"));
  }

  function isMinted(uint _id) public view returns (bool) {
    return tokenOwner[_id] != address(0);
  }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155PresetMinterPauser) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
    if (hasRole(MINTER_ROLE, operator)) {
      return true;
    }

    return super.isApprovedForAll(account, operator);
  }

  function refreshMetadata(uint[] memory ids) public virtual {
    string[] memory uris = new string[](ids.length);
    for (uint i = 0; i < ids.length; i++) {
      uris[i] = uri(ids[i]);
    }
    emit RefreshMetadata(ids, uris);
  }

  function mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public override {
    _requireMinterRole();
    _mint(to, id, amount, data);
  }

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public override {
    _requireMinterRole();
    _mintBatch(to, ids, amounts, data);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override(ERC1155PresetMinterPauser) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

    for (uint i = 0; i < ids.length; i++) {
      tokenOwner[ids[i]] = to;
    }
  }

  function _requireMinterRole() internal view {
    require(hasRole(MINTER_ROLE, _msgSender()), "Must have minter role");
  }

  function _requireAdminRole() internal view {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have admin role");
  }
}
