
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BinaryDecoder.sol";
import "./Strings.sol";

library PackedVarArray {
  function getString(bytes32[0xFFFF] storage buffers, uint offset, uint len) internal view returns (string memory) {
    bytes memory result = new bytes(len);

    uint bufferIdx = offset / 32;
    uint bufferOffset = offset % 32;
    uint outIdx = 0;
    uint remaining = len;
    uint bufferCap = 32 - bufferOffset;


    while (outIdx < len) {
      uint copyCount = remaining > bufferCap ? bufferCap : remaining;
      uint lastOffset = bufferOffset + copyCount;
      bytes32 buffer = bytes32(buffers[bufferIdx]);
      while( bufferOffset < lastOffset) {
        result[outIdx++] = buffer[bufferOffset++];
      }
      remaining -= copyCount;
      bufferCap = 32;
      bufferOffset = 0;
      bufferIdx++;
    }

    return string(result);
  }

  function getString(bytes32[0xFFFF] storage buffers, uint index) internal view returns (string memory) {
    uint offsetLoc = uint(index) * 4;
    uint stringOffsetLen;
    (stringOffsetLen,,) = BinaryDecoder.decodeUint32Aligned(buffers, offsetLoc / 32, offsetLoc % 32);
    uint stringOffset = stringOffsetLen & 0xFFFF;
    uint stringLen = stringOffsetLen >> 16;

    return getString(buffers, stringOffset, stringLen);
  }

  function getStringInfo(bytes32[0xFFFF] storage buffers, uint index) internal view returns ( bytes32 firstSlot, uint offset, uint length ) {
    uint offsetLoc = uint(index) * 4;
    uint stringOffsetLen;
    (stringOffsetLen,,) = BinaryDecoder.decodeUint32Aligned(buffers, offsetLoc / 32, offsetLoc % 32);
    uint stringOffset = stringOffsetLen & 0xFFFF;
    uint stringLen = stringOffsetLen >> 16;
    uint bufferIdx = stringOffset / 32;
    uint bufferOffset = stringOffset % 32;
    bytes32 bufferSlot;

    //solhint-disable-next-line no-inline-assembly
    assembly {
      bufferSlot := buffers.slot
    }

    bufferSlot = bytes32(uint(bufferSlot) +  bufferIdx);


    return (bufferSlot, bufferOffset, stringLen);
  }

  function getStringLength(bytes32[0xFFFF] storage buffers, uint index) internal view returns (uint) {
    uint offsetLoc = uint(index) * 4;
    uint stringOffsetLen;
    (stringOffsetLen,,) = BinaryDecoder.decodeUint32Aligned(buffers, offsetLoc / 32, offsetLoc % 32);
    return stringOffsetLen >> 24;
  }

  function getUint16Array(bytes32[0xFFFF] storage buffers, uint offset, uint len) internal view returns (uint16[] memory) {
    uint16[] memory result = new uint16[](len);

    uint bufferIdx = offset / 32;
    uint bufferOffset = offset % 32;
    uint outIdx = 0;
    uint remaining = len * 2;
    uint bufferCap = 32 - bufferOffset;


    while (outIdx < len) {
      uint copyCount = remaining > bufferCap ? bufferCap : remaining;
      uint lastOffset = bufferOffset + copyCount;
      bytes32 buffer = bytes32(buffers[bufferIdx]);
      while (bufferOffset < lastOffset) {
        result[outIdx]  = uint16(uint8(buffer[bufferOffset++])) << 8;
        result[outIdx] |= uint16(uint8(buffer[bufferOffset++]));
        outIdx++;
      }
      remaining -= copyCount;
      bufferCap = 32;
      bufferOffset = 0;
      bufferIdx++;
    }

    return result;
  }

  function getUint16Array(bytes32[0xFFFF] storage buffers, uint index) internal view returns (uint16[] memory) {
    uint offsetLoc = uint(index) * 4;
    uint arrOffsetLen;
    (arrOffsetLen, ,) = BinaryDecoder.decodeUint32Aligned(buffers, offsetLoc / 32, offsetLoc % 32);
    uint arrOffset = arrOffsetLen & 0xFFFFFF;
    uint arrLen = arrOffsetLen >> 24;

    return getUint16Array(buffers, arrOffset, arrLen);
  }

  function getUint16ArrayInfo(bytes32[0xFFFF] storage buffers, uint index) internal view returns ( uint, uint, uint ) {
    uint offsetLoc = uint(index) * 4;
    uint arrOffsetLen;
    (arrOffsetLen, ,) = BinaryDecoder.decodeUint32Aligned(buffers, offsetLoc / 32, offsetLoc % 32);
    uint arrOffset = arrOffsetLen & 0xFFFFFF;
    uint arrLen = arrOffsetLen >> 24;
    uint bufferIdx = arrOffset / 32;
    uint bufferOffset = arrOffset % 32;

    return (bufferIdx, bufferOffset, arrLen);
  }
}
