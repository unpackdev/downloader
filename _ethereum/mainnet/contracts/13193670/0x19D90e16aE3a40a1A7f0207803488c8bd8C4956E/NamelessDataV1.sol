// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BinaryDecoder.sol";
import "./PackedVarArray.sol";


library NamelessDataV1 {
  /*
   * up to 2^32 generations each separated in space by
   * 2^223 empty slots for safety
   * leaving 223 bits of space for collision resistance
   */
  function getGenerationalSlot(uint256 columnName, uint32 generation) internal pure returns (uint256) {
    uint256 finalSlot =
      (columnName & 0x000000007FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) |
      (uint(generation) << 224);

    return finalSlot;
  }

  /*
   * Special Column Types
   */

  uint256 private constant MAX_COLUMN_WORDS = 65535;
  uint256 private constant MAX_CONTENT_LIBRARIES_PER_COLUMN = 256;
  uint256 private constant CONTENT_LIBRARY_SECTION_SIZE = 32 * MAX_CONTENT_LIBRARIES_PER_COLUMN;

  uint256 public constant COLUMN_TYPE_STRING = 1;
  uint256 public constant COLUMN_TYPE_UINT256 = 2;
  uint256 public constant COLUMN_TYPE_UINT128 = 3;
  uint256 public constant COLUMN_TYPE_UINT64 = 4;
  uint256 public constant COLUMN_TYPE_UINT32 = 5;
  uint256 public constant COLUMN_TYPE_UINT16 = 6;
  uint256 public constant COLUMN_TYPE_UINT8  = 7;
  uint256 public constant COLUMN_TYPE_NATIVE_STRING = 8;

  /**
    * @dev Returns an `uint256[MAX_COLUMN_WORDS]` located at `slot`.
    */
  function getColumn(bytes32 slot) internal pure returns (bytes32[MAX_COLUMN_WORDS] storage r) {
      // solhint-disable-next-line no-inline-assembly
      assembly {
          r.slot := slot
      }
  }

  function getBufferIndexAndOffset(uint index, uint stride) internal pure returns (uint, uint) {
    uint offset = index * stride;
    return (offset / 32, offset % 32);
  }

  function getBufferIndexAndOffset(uint index, uint stride, uint baseOffset) internal pure returns (uint, uint) {
    uint offset = (index * stride) + baseOffset;
    return (offset / 32, offset % 32);
  }

  /*
   * Content Library Column
   *
   * @dev a content library column references content from a secondary data source like arweave of IPFS
   *      this content has been batched into libraries to save space.  Each library is a JSON-encoded
   *      array stored on the secondary data source that provides an indirection to the "real" content.
   *      each content library can hold up to 256 content references and each column can reference 256
   *      libraries. This results in a total of 65536 addressable content hashes while only consuming
   *      2 bytes per distinct token.
   */
  function readContentLibraryColumn(bytes32 columnSlot, uint ordinal) public view returns (
    uint contentLibraryHash,
    uint contentIndex
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    (uint bufferIndex, uint offset) = getBufferIndexAndOffset(ordinal, 2, CONTENT_LIBRARY_SECTION_SIZE);
    uint row = 0;
    (row, , ) = BinaryDecoder.decodeUint16Aligned(column, bufferIndex, offset);

    uint contentLibraryIndex = row >> 8;
    contentIndex = row & 0xFF;
    contentLibraryHash = uint256(column[contentLibraryIndex]);
  }

  function readDictionaryString(bytes32 dictionarySlot, uint ordinal) public view returns ( string memory ) {
    return PackedVarArray.getString(getColumn(dictionarySlot), ordinal);
  }

  function getDictionaryStringInfo(bytes32 dictionarySlot, uint ordinal) internal view returns ( bytes32 firstSlot, uint offset, uint length ) {
    return PackedVarArray.getStringInfo(getColumn(dictionarySlot), ordinal);
  }

  function readDictionaryStringLength(bytes32 dictionarySlot, uint ordinal) public view returns ( uint ) {
    return PackedVarArray.getStringLength(getColumn(dictionarySlot), ordinal);
  }

  /*
   * Uint256 Column
   *
   */
  function readUint256Column(bytes32 columnSlot, uint ordinal) public view returns (
    uint
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    return uint256(column[ordinal]);
  }

  /*
   * Uint128 Column
   *
   */
  function readUint128Column(bytes32 columnSlot, uint ordinal) public view returns (
    uint
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    uint bufferIndex = ordinal / 2;
    uint shift = (1 - (ordinal % 2)) * 128;
    return (uint256(column[bufferIndex]) >> shift) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  }

  /*
   * Uint64 Column
   *
   */
  function readUint64Column(bytes32 columnSlot, uint ordinal) public view returns (
    uint
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    uint bufferIndex = ordinal / 4;
    uint shift = (3 - (ordinal % 4)) * 64;
    return (uint256(column[bufferIndex]) >> shift) & 0xFFFFFFFFFFFFFFFF;
  }

  /*
   * Uint32 Column
   *
   */
  function readUint32Column(bytes32 columnSlot, uint ordinal) public view returns (
    uint
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    uint bufferIndex = ordinal / 8;
    uint shift = (7 - (ordinal % 8)) * 32;
    return (uint256(column[bufferIndex]) >> shift) & 0xFFFFFFFF;
  }

  /*
   * Uint16 Column
   *
   */
  function readUint16Column(bytes32 columnSlot, uint ordinal) public view returns (
    uint
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    uint bufferIndex = ordinal / 16;
    uint shift = (15 - (ordinal % 16)) * 16;
    return (uint256(column[bufferIndex]) >> shift) & 0xFFFF;
  }

  /*
   * Uint8 Column
   *
   */
  function readUint8Column(bytes32 columnSlot, uint ordinal) public view returns (
    uint
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    uint bufferIndex = ordinal / 32;
    uint shift = (31 - (ordinal % 32)) * 8;
    return (uint256(column[bufferIndex]) >> shift) & 0xFF;
  }

}
