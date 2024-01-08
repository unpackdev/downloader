// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import "./ERC1155.sol";
import "./IyusdiNftV3Base.sol";
import "./Console.sol";

contract OwnableDelegateProxy {}
contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract IyusdiNftV3 is IyusdiNftV3Base, ERC1155 {

  address proxyRegistryAddress;

  constructor (address _operator, address _curator, string memory _uri, address _proxyRegistryAddress) ERC1155(_uri) {
    require(_curator != address(0) && _operator != address(0), '!param');
    proxyRegistryAddress = _proxyRegistryAddress;
    curator = _curator;
    operators[_operator] = true;
    setApprovalForAll(_operator, true);
    _mint(_curator, CURATOR_ID, 1, "");
    emit CuratorMinted(_curator, CURATOR_ID);
  }

  function isApprovedForAll(address _owner, address _operator) public view virtual override returns(bool isOperator) {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }
    return ERC1155.isApprovedForAll(_owner, _operator);
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

  function _isPrintOwner(uint256 id) internal view returns(bool) {
    return balanceOf(msg.sender, id) > 0;
  }

  function _canTransfer(uint256 id, address _operator) internal view returns(bool) {
    if (operators[_operator] || _isOgId(id) || _isPrintOwner(id)) {
      return true;
    } else {
      uint256 og = _getOgId(id);
      return canTransfer[og];
    }
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