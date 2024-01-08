// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import "./ERC1155.sol";
import "./IyusdiNftV2Base.sol";
import "./Console.sol";

contract IyusdiNftV2 is IyusdiNftV2Base, ERC1155 {

  constructor (address _operator, address _curator, string memory _uri) ERC1155(_uri) {
    require(_curator != address(0) && _operator != address(0), '!param');
    curator = _curator;
    operators[_operator] = true;
    setApprovalForAll(_operator, true);
    _mint(_curator, CURATOR_ID, 1, "");
    emit CuratorMinted(_curator, CURATOR_ID);
  }

  function setOperator(address operator, bool set) onlyCurator external {
    require(operator != address(0), '!operator');
    operators[operator] = set;
    setApprovalForAll(operator, set);
  }

  function owns(uint256 id, address owner) external view returns(bool) {
    return balanceOf(owner, id) > 0;
  }

  function mintOriginal(address owner, bytes memory data) external returns(uint256 id) {
    id = _mintOriginal(owner, data);
    _mint(owner, id, 1, "");
  }

  function mintPrint(uint256 og, address to, bytes memory data) external returns(uint256 id) {
    id = _mintPrint(og, to, data);
    _mint(to, id, 1, "");
  }

  function burnPrint(address from, uint256 id) external {
    _burnPrint(from, id);
    _burn(from, id, 1);
  }

  /***********************************|
  |        Hooks                      |
  |__________________________________*/
  function _beforeTokenTransfer(
    address _operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    super._beforeTokenTransfer(_operator, from, to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      require(_canTransfer(id, _operator), '!transfer');
      if (id == CURATOR_ID) {
        curator = to;
      } else if (_isOgId(id)) {
        originalOwner[id] = to;   
      }
    }
  }

  /**
      * @dev See {IERC165-supportsInterface}.
      */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return ERC1155.supportsInterface(interfaceId);
  }

}