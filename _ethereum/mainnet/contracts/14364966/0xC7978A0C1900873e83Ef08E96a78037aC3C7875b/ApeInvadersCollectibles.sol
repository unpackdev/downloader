// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Supply.sol";

contract ApeInvadersCollectibles is ERC1155, Ownable, ERC1155Supply {
  // solhint-disable-next-line no-empty-blocks
  constructor() ERC1155("ipfs://QmZ3ooPPQxSeAo1fzdXDeiUjz9yiZJG2rRvA4ekQyCF3Sr/") {}

  function setURI(string memory newUri) public onlyOwner {
    _setURI(newUri);
  }

  function mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public onlyOwner {
    _mint(account, id, amount, data);
  }

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public onlyOwner {
    _mintBatch(to, ids, amounts, data);
  }

  function uri(uint256 _id)
    public
    view
    virtual
    override(ERC1155)
    returns (string memory)
  {
    require(exists(_id), "Token does not exist");
    return string(abi.encodePacked(super.uri(0), Strings.toString(_id)));
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155, ERC1155Supply) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
}
