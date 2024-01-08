// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

contract IyusdiNftV2Base {

  event FeedItem(
    uint256 indexed id,
    uint256 indexed hash,
    uint256 timestamp,
    bytes data
  );

  event CuratorMinted(
    address owner,
    uint256 id
  );

  event OriginalMinted(
    address indexed owner,
    uint256 indexed id
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
    uint64 mintedPrints;
    uint64 printIndex;
  }

  uint256 public constant OG_MASK     = 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
  uint256 public constant OG_INV_MASK = 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000;
  uint256 public constant CURATOR_ID  = 0x8000000000000000000000000000000000000000000000000000000000000000;

  address public curator;
  Original[] public originals;
  mapping (address => bool) public operators;
  mapping (uint256 => bool) public canTransfer;
  mapping (uint256 => address) public originalOwner;

  modifier onlyCurator() {
    require(msg.sender == curator, "!curator");
    _;
  }

  function _getOgOwner(uint256 id) internal view returns (address) {
    return id == CURATOR_ID ? curator : originalOwner[_getOgId(id)];
  }

  function originalIndex(uint256 id) external pure returns(uint256) {
    uint256 og = _getOgId(id);
    return (og >> 128) - 1;
  }

  function originalMintedPrints(uint256 id) external view returns(uint256) {
    uint256 og = _getOgId(id);
    uint256 idx = (og >> 128) - 1;
    return originals[idx].mintedPrints;
  }

  function post(uint256 id, uint256 hash, bytes memory data) external {
    require(_isOperator(), '!operator');
    uint256 og = _getOgId(id);
    address owner = _getOgOwner(og);
    require(owner != address(0), '!owner');
    emit FeedItem(id, hash, block.timestamp, data);
  }

  function getOgId(uint256 id) external pure returns (uint256) {
    return _getOgId(id);
  }

  function _getOgId(uint256 id) internal pure returns (uint256) {
    return id & OG_INV_MASK;
  }

  function isOgId(uint256 id) external pure returns (bool) {
    return _isOgId(id);
  }

  function _isOgId(uint256 id) internal pure returns (bool) {
    return (id & OG_MASK) == 0;
  }

  function isPrintId(uint256 id) external pure returns (bool) {
    return _isPrintId(id);
  }

  function _isPrintId(uint256 id) internal pure returns (bool) {
    return (id & OG_MASK) > 0;
  }

  function _isCurator() internal view returns(bool) {
    return msg.sender == curator;
  }

  function _isOperator() internal view returns(bool) {
    return operators[msg.sender];
  }

  function _mintOriginal(address owner, bytes memory data) internal returns(uint256 id) {
    require(_isOperator() && owner != address(0), '!parm');
    originals.push(Original(0, 0));
    id = originals.length << 128;
    originalOwner[id] = owner;
    emit OriginalMinted(owner, id);
    emit FeedItem(id, 0, block.timestamp, data);
  }

  function _mintPrint(uint256 og, address to, bytes memory data) internal returns(uint256 id) {
    require(_isOperator() && _isOgId(og), '!ogId');
    uint256 idx = (og >> 128) - 1;
    Original storage original = originals[idx];
    original.mintedPrints++;
    original.printIndex++;
    id = og | original.printIndex;
    emit PrintMinted(to, og, id);
    emit FeedItem(id, 0, block.timestamp, data);
  }

  function _burnPrint(address from, uint256 id) internal {
    require(_isOperator() && _isPrintId(id), '!printId');
    uint256 og = _getOgId(id);
    uint256 idx = (og >> 128) - 1;
    Original storage original = originals[idx];
    original.mintedPrints = original.mintedPrints - 1;
    emit PrintBurned(from, id);
  }

  function _canTransfer(uint256 id, address _operator) internal view returns(bool) {
    if (_isOgId(id) || operators[_operator]) {
      return true;
    } else {
      uint256 og = _getOgId(id);
      return canTransfer[og];
    }
  }

  function allowTransfers(uint256 id, bool can) external {
    require(_isOperator(), '!operator');
    uint256 og = _getOgId(id);
    canTransfer[og] = can;
  }

}