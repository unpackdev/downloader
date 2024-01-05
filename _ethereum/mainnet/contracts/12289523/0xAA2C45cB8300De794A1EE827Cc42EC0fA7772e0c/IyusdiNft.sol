// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import "./ERC1155.sol";
import "./Console.sol";

contract IyusdiNft is ERC1155 {

  event FeedItem(
    uint256 indexed id,
    uint256 indexed hash,
    uint256 timestamp,
    string ipfsHash
  );

  event CuratorMinted(
    address owner,
    uint256 id
  );

  event OriginalMinted(
    address indexed owner,
    address creator,
    uint256 indexed id,
    uint64 maxPrints
  );

  event PrintMinted(
    address indexed owner,
    uint256 indexed og,
    uint256 indexed id
  );

  event PrintBurned(
    address from,
    uint256 id
  );

  struct Original {
    address creator;
    uint64 maxPrints;
    uint64 totalPrints;
    uint64 printIndex;
  }

  uint256 public constant OG_MASK     = 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
  uint256 public constant OG_INV_MASK = 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000;
  uint256 public constant CURATOR_ID  = 0x8000000000000000000000000000000000000000000000000000000000000000;

  address public curator;
  address public operator;
  Original[] public originals;
  mapping (uint256 => bool) public canTransfer;
  mapping (uint256 => address) public originalOwner;

  constructor (address _operator, address _curator, string memory _uri) ERC1155(_uri) {
    require(_curator != address(0), '!curator');
    _mint(_curator, CURATOR_ID, 1, "");
    emit CuratorMinted(_curator, CURATOR_ID);
    curator = _curator;
    operator = _operator;
    setApprovalForAll(_operator, true);
  }

  function _getOgOwner(uint256 id) internal view returns (address) {
    return id == CURATOR_ID ? curator : originalOwner[_getOgId(id)];
  }

  function owns(uint256 id, address owner) external view returns(bool) {
    return balanceOf(owner, id) > 0;
  }

  function post(uint256 id, uint256 hash, string memory ipfs) external {
    require(_isOperator(), '!operator');
    uint256 og = _getOgId(id);
    address owner = _getOgOwner(og);
    require(owner != address(0), '!owner');
    emit FeedItem(id, hash, block.timestamp, ipfs);
  }

  function _getOgId(uint256 id) internal pure returns (uint256) {
    return id & OG_INV_MASK;
  }

  function _isOgId(uint256 id) internal pure returns (bool) {
    return (id & OG_MASK) == 0;
  }

  function _isPrintId(uint256 id) internal pure returns (bool) {
    return (id & OG_MASK) > 0;
  }

  function _isOperator() internal view returns(bool) {
    return operator == address(0) || msg.sender == operator;
  }

  function mintOriginal(address owner, address creator, uint64 maxPrints, string memory ipfs) external returns(uint256 id) {
    require(_isOperator() && owner != address(0) && creator != address(0), '!parm');
    originals.push(Original(creator, maxPrints, 0, 0));
    id = originals.length << 128;
    originalOwner[id] = owner;
    _mint(owner, id, 1, "");
    emit OriginalMinted(owner, creator, id, maxPrints);
    emit FeedItem(id, 0, block.timestamp, ipfs);
  }

  function mintPrint(uint256 og, address to, string memory ipfs) external returns(uint256 id) {
    require(_isOperator() && _isOgId(og), '!ogId');
    uint256 idx = (og >> 128) - 1;
    Original storage original = originals[idx];
    require(original.maxPrints == 0 || (original.totalPrints + 1 < original.maxPrints), '!maxPrints');
    original.totalPrints++;
    original.printIndex++;
    id = og | original.printIndex;
    _mint(to, id, 1, "");
    emit PrintMinted(to, og, id);
    emit FeedItem(id, 0, block.timestamp, ipfs);
  }

  function burnPrint(address from, uint256 id) external {
    require(_isOperator() && _isPrintId(id), '!printId');
    uint256 og = _getOgId(id);
    uint256 idx = (og >> 128) - 1;
    Original storage original = originals[idx];
    original.totalPrints = original.totalPrints - 1;
    _burn(from, id, 1);
    emit PrintBurned(from, id);
  }

  function _canTransfer(uint256 id, address _operator) internal view returns(bool) {
    if (operator == address(0) || operator == _operator || _isOgId(id)) {
      return true;
    } else {
      uint256 og = _getOgId(id);
      return canTransfer[og];
    }
  }

  function allowTransfers(uint256 id, bool can) external {
    require(operator == msg.sender, '!operator');
    uint256 og = _getOgId(id);
    canTransfer[og] = can;
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