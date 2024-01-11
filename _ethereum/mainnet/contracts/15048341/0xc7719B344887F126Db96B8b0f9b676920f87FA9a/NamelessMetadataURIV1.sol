// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./StorageSlot.sol";
import "./Strings.sol";

import "./NamelessDataV1.sol";
import "./Base64.sol";

library NamelessMetadataURIV1 {
  bytes constant private BASE_64_URL_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

  function base64EncodeBuffer(bytes memory buffer, bytes memory output, uint outOffset) internal pure returns (uint) {
    uint outLen = (buffer.length + 2) / 3 * 4 - ((3 - ( buffer.length % 3 )) % 3);

    uint256 i = 0;
    uint256 j = outOffset;

    for (; i + 3 <= buffer.length; i += 3) {
        (output[j], output[j+1], output[j+2], output[j+3]) = base64Encode3(
            uint8(buffer[i]),
            uint8(buffer[i+1]),
            uint8(buffer[i+2])
        );

        j += 4;
    }

    if ((i + 2) == buffer.length) {
      (output[j], output[j+1], output[j+2], ) = base64Encode3(
          uint8(buffer[i]),
          uint8(buffer[i+1]),
          0
      );
    } else if ((i + 1) == buffer.length) {
      (output[j], output[j+1], , ) = base64Encode3(
          uint8(buffer[i]),
          0,
          0
      );
    }

    return outOffset + outLen;
  }

  function base64Encode(uint256 bigint, bytes memory output, uint outOffset) internal pure returns (uint) {
      bytes32 buffer = bytes32(bigint);

      uint256 i = 0;
      uint256 j = outOffset;

      for (; i + 3 <= 32; i += 3) {
          (output[j], output[j+1], output[j+2], output[j+3]) = base64Encode3(
              uint8(buffer[i]),
              uint8(buffer[i+1]),
              uint8(buffer[i+2])
          );

          j += 4;
      }
      (output[j], output[j+1], output[j+2], ) = base64Encode3(uint8(buffer[30]), uint8(buffer[31]), 0);
      return outOffset + 43;
  }

  function base64Encode3(uint256 a0, uint256 a1, uint256 a2)
      internal
      pure
      returns (bytes1 b0, bytes1 b1, bytes1 b2, bytes1 b3)
  {

      uint256 n = (a0 << 16) | (a1 << 8) | a2;

      uint256 c0 = (n >> 18) & 63;
      uint256 c1 = (n >> 12) & 63;
      uint256 c2 = (n >>  6) & 63;
      uint256 c3 = (n      ) & 63;

      b0 = BASE_64_URL_CHARS[c0];
      b1 = BASE_64_URL_CHARS[c1];
      b2 = BASE_64_URL_CHARS[c2];
      b3 = BASE_64_URL_CHARS[c3];
  }

  bytes constant private BASE_58_CHARS = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  function ipfsCidEncode(bytes32 value, bytes memory output, uint outOffset) internal pure returns (uint) {
    uint encodedLen = 0;
    for (uint idx = 0; idx < 34; idx++)
    {
      uint carry = 0;
      if (idx >= 2) {
        carry = uint8(value[idx - 2]);
      } else if (idx == 1) {
        carry = 0x20;
      } else if (idx == 0) {
        carry = 0x12;
      }

      for (uint jdx = 0; jdx < encodedLen; jdx++)
      {
        carry = carry + (uint(uint8(output[outOffset + 45 - jdx])) << 8);
        output[outOffset + 45 - jdx] = bytes1(uint8(carry % 58));
        carry /= 58;
      }
      while (carry > 0) {
        output[outOffset + 45 - encodedLen++] = bytes1(uint8(carry % 58));
        carry /= 58;
      }
    }

    for (uint idx = 0; idx < 46; idx++) {
      output[outOffset + idx] = BASE_58_CHARS[uint8(output[outOffset + idx])];
    }

    return outOffset + 46;
  }

  function base10Encode(uint256 bigint, bytes memory output, uint outOffset) internal pure returns (uint) {
    bytes memory alphabet = '0123456789';
    if (bigint == 0) {
      output[outOffset] = alphabet[0];
      return outOffset + 1;
    }

    uint digits = 0;
    uint value = bigint;
    while (value > 0) {
      digits++;
      value = value / 10;
    }

    value = bigint;
    uint currentOffset = outOffset + digits - 1;
    while (value > 0) {
      output[currentOffset] = alphabet[value % 10];
      currentOffset--;
      value = value / 10;
    }

    return outOffset + digits;
  }



  function writeAddressToString(address addr, bytes memory output, uint outOffset) internal pure returns(uint) {
    bytes32 value = bytes32(uint256(uint160(addr)));
    bytes memory alphabet = '0123456789abcdef';

    output[outOffset++] = '0';
    output[outOffset++] = 'x';
    for (uint256 i = 0; i < 20; i++) {
      output[outOffset + (i*2) ]    = alphabet[uint8(value[i + 12] >> 4)];
      output[outOffset + (i*2) + 1] = alphabet[uint8(value[i + 12] & 0x0f)];
    }
    outOffset += 40;
    return outOffset;
  }

  function copyDictionaryString(Context memory context, bytes32 columnSlot, uint256 ordinal) internal view returns (uint) {
    bytes32 curSlot;
    uint offset;
    uint length;
    (curSlot, offset, length) = NamelessDataV1.getDictionaryStringInfo(columnSlot, ordinal);

    bytes32 curBuffer;
    uint remaining = length;
    uint bufferCap = 32 - offset;
    uint outIdx = 0;

    while (outIdx < length) {
      uint copyCount = remaining > bufferCap ? bufferCap : remaining;
      uint lastOffset = offset + copyCount;
      curBuffer = StorageSlot.getBytes32Slot(curSlot).value;

      while( offset < lastOffset) {
        context.output[context.outOffset + outIdx++] = curBuffer[offset++];
      }
      remaining -= copyCount;
      bufferCap = 32;
      offset = 0;
      curSlot = bytes32(uint(curSlot) + 1);
    }

    return context.outOffset + outIdx;
  }

  function copyString(Context memory context, string memory value) internal pure returns (uint) {
    for (uint idx = 0; idx < bytes(value).length; idx++) {
      context.output[context.outOffset + idx] = bytes(value)[idx];
    }

    return context.outOffset + bytes(value).length;
  }

  function copyNativeString(Context memory context, bytes32 columnSlot, uint256 ordinal) internal view returns (uint) {
    string[] storage nativeStrings;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      nativeStrings.slot := columnSlot
    }

    bytes storage buffer = bytes(nativeStrings[ordinal]);
    uint length = buffer.length;

    for (uint idx = 0; idx < length; idx++) {
      context.output[context.outOffset + idx] = buffer[idx];
    }

    return context.outOffset + length;
  }


  struct Context {
    uint codeBufferIndex;
    uint codeBufferOffset;
    uint256 tokenId;
    uint32 generation;
    uint   index;
    address owner;
    string arweaveContentApi;
    string ipfsContentApi;

    uint opsRetired;

    uint outOffset;
    bytes output;
    bool done;
    uint8  stackLength;
    bytes32[0xFF] stack;
  }

  // 4byte opcode to write the bytes32 at the top of the stack to the output raw and consume it
  // byte 1 is the write codepoint,
  // byte 2 is the write format (0 = raw, 1 = hex, 2 = base64),
  // byte 3 is the offset big-endian to start at and
  // byte 4 is the big-endian byte to stop at (non-inclusive)
  function execWrite(Context memory context, bytes32[] memory, bytes32[] memory codeSegment) internal pure {
    require(context.stackLength > 0, 'stack underflow');
    uint format = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
    incrementCodeOffset(context);

    uint start = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
    incrementCodeOffset(context);

    uint end = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
    incrementCodeOffset(context);

    if (format == 0) {
      bytes32 stackTop = bytes32(context.stack[context.stackLength - 1]);
      for (uint idx = start; idx < end; idx++) {
        context.output[ context.outOffset ++ ] = stackTop[idx];
      }
    } else if (format == 1) {
      uint256 stackTop = uint256(context.stack[context.stackLength - 1]);
      bytes memory alphabet = '0123456789abcdef';
      uint startNibble = start * 2;
      uint endNibble = end * 2;

      stackTop >>= (64 - endNibble) * 4;

      context.output[context.outOffset++] = '0';
      context.output[context.outOffset++] = 'x';
      for (uint256 i = endNibble-1; i >= startNibble; i--) {
        uint nibble = stackTop & 0xf;
        stackTop >>= 4;
        context.output[context.outOffset + i - startNibble ] = alphabet[nibble];
      }
      context.outOffset += endNibble - startNibble;
    } else if (format == 2) {
      uint256 stackTop = uint256(context.stack[context.stackLength - 1]);
      if (start == 0 && end == 32) {
        context.outOffset = base64Encode(stackTop, context.output, context.outOffset);
      } else {
        uint length = end - start;
        bytes memory temp = new bytes(length);
        for (uint idx = 0; idx < length; idx++) {
          temp[idx] = bytes32(stackTop)[start + idx];
        }
        context.outOffset = base64EncodeBuffer(temp, context.output, context.outOffset);
      }
    } else if (format == 3) {
      require(start == 0 && end == 32, 'invalid cid length');
      context.outOffset = ipfsCidEncode(context.stack[context.stackLength - 1], context.output, context.outOffset);
    } else if (format == 4) {
      uint mask = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF >> (start * 8);
      uint shift = (32 - end) * 8;
      uint value = (uint256(context.stack[context.stackLength - 1]) & mask) >> shift;
      context.outOffset = base10Encode(value, context.output, context.outOffset);
    }


    context.stackLength--;
  }
  // 2byte opcode to write the column-specific data indicated by the column name on the top of the stack
  // this column has "typed" data like strings etc
  function execWriteContext(Context memory context, bytes32[] memory, bytes32[] memory codeSegment) internal view {
    require(context.stack.length > 0, 'stack underflow');
    uint contextId = uint(context.stack[context.stackLength - 1]);
    context.stackLength--;

    uint format = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
    incrementCodeOffset(context);

    if (contextId == CONTEXT_TOKEN_ID || contextId == CONTEXT_TOKEN_OWNER || contextId == CONTEXT_BLOCK_TIMESTAMP || contextId == CONTEXT_GENERATION || contextId == CONTEXT_INDEX ) {
      require(format != 0, 'invalid format for uint256');
      uint value = 0;
      if (contextId == CONTEXT_TOKEN_ID) {
        value = context.tokenId;
      } else if (contextId == CONTEXT_TOKEN_OWNER ) {
        value = uint256(uint160(context.owner));
      } else if (contextId == CONTEXT_BLOCK_TIMESTAMP ) {
        // solhint-disable-next-line not-rely-on-time
        value = uint256(block.timestamp);
      } else if (contextId == CONTEXT_GENERATION ) {
        value = context.generation;
      } else if (contextId == CONTEXT_INDEX ) {
        value = context.index;
      }

      if (format == 1) {
        bytes memory alphabet = '0123456789abcdef';
        context.output[context.outOffset++] = '0';
        context.output[context.outOffset++] = 'x';
        for (uint256 i = 0; i < 64; i++) {
          uint nibble = value & 0xf;
          value >>= 4;
          context.output[context.outOffset + 63 - i] = alphabet[nibble];
        }
        context.outOffset += 64;
      } else if (format == 2) {
        context.outOffset = base64Encode(value, context.output, context.outOffset);
      } else if (format == 4) {
        context.outOffset = base10Encode(value, context.output, context.outOffset);
      }

    } else if (contextId == CONTEXT_ARWEAVE_CONTENT_API || contextId == CONTEXT_IPFS_CONTENT_API ) {
      require(format == 0, 'invalid format for string');
      string memory value;
      if (contextId == CONTEXT_ARWEAVE_CONTENT_API) {
        value = context.arweaveContentApi;
      } else if ( contextId == CONTEXT_IPFS_CONTENT_API) {
        value = context.ipfsContentApi;
      }

      context.outOffset = copyString(context, value);
    } else {
      revert(string(abi.encodePacked('Unknown/unsupported context ID', Strings.toString(contextId))));
    }
  }

  // 2byte opcode to write the column-specific data indicated by the column name on the top of the stack
  // this column has "typed" data like strings etc
  function execWriteColumnar(Context memory context, bytes32[] memory, bytes32[] memory codeSegment) internal view {
    require(context.stack.length > 1, 'stack underflow');
    bytes32 rawColumnSlot = context.stack[context.stackLength - 2];
    bytes32 columnSlot = bytes32(NamelessDataV1.getGenerationalSlot(uint(rawColumnSlot), context.generation));
    uint columnIndex = uint(context.stack[context.stackLength - 1]);
    context.stackLength -= 2;

    uint format = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
    incrementCodeOffset(context);

    uint256 columnMetadata = StorageSlot.getUint256Slot(columnSlot).value;
    uint columnType = (columnMetadata >> 248) & 0xFF;

    if (columnType == NamelessDataV1.COLUMN_TYPE_NATIVE_STRING) {
      require(format == 0, 'invalid format for string');
      context.outOffset = copyNativeString(context, bytes32(uint256(columnSlot) + 1), columnIndex);
    } else if (columnType == NamelessDataV1.COLUMN_TYPE_STRING) {
      require(format == 0, 'invalid format for string');
      context.outOffset = copyDictionaryString(context, bytes32(uint256(columnSlot) + 1), columnIndex);
    } else if (columnType >= NamelessDataV1.COLUMN_TYPE_UINT256 && columnType <= NamelessDataV1.COLUMN_TYPE_UINT8) {
      require(format != 0, 'invalid format for uint');
      uint value = 0;

      if (columnType == NamelessDataV1.COLUMN_TYPE_UINT256) {
        value = NamelessDataV1.readUint256Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      } else if (columnType == NamelessDataV1.COLUMN_TYPE_UINT128) {
        value = NamelessDataV1.readUint128Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      } else if (columnType == NamelessDataV1.COLUMN_TYPE_UINT64) {
        value = NamelessDataV1.readUint64Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      } else if (columnType == NamelessDataV1.COLUMN_TYPE_UINT32) {
        value = NamelessDataV1.readUint32Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      } else if (columnType == NamelessDataV1.COLUMN_TYPE_UINT16) {
        value = NamelessDataV1.readUint16Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      } else if (columnType == NamelessDataV1.COLUMN_TYPE_UINT8) {
        value = NamelessDataV1.readUint8Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      }

      if (format == 1) {
        bytes memory alphabet = '0123456789abcdef';
        context.output[context.outOffset++] = '0';
        context.output[context.outOffset++] = 'x';
        for (uint256 i = 0; i < 64; i++) {
          uint nibble = value & 0xf;
          value >>= 4;
          context.output[context.outOffset + 63 - i] = alphabet[nibble];
        }
        context.outOffset += 64;
      } else if (format == 2) {
        context.outOffset = base64Encode(value, context.output, context.outOffset);
      } else if (format == 3) {
        context.outOffset = ipfsCidEncode(bytes32(value), context.output, context.outOffset);
      } else if (format == 4) {
        context.outOffset = base10Encode(value, context.output, context.outOffset);
      }
    } else {
      revert('unknown column type');
    }
  }

  // 1byte opcode to push the bytes32 at a given index in the data section onto the stack
  // byte 1 is the push codepoint,
  function execPushData(Context memory context, bytes32[] memory dataSegment, bytes32[] memory) internal pure {
    context.stack[context.stackLength-1] = dataSegment[uint256(context.stack[context.stackLength-1])];
  }

  // Nbyte opcode to push the immediate bytes in the codeSegment onto the stack
  // byte 1 is the pushImmediate codepoint,
  // byte 2 big-endian offset to write the first loaded byte from
  // byte 3 number of immediate bytes
  // bytes 4-N big-endian immediate bytes
  function execPushImmediate(Context memory context, bytes32[] memory, bytes32[] memory codeSegment) internal pure {
    uint startShiftByte = 31 - uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
    incrementCodeOffset(context);

    uint length = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
    incrementCodeOffset(context);

    uint256 value = 0;
    for (uint idx = 0; idx < length; idx++) {
      uint byteVal = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);
      incrementCodeOffset(context);
      value |= byteVal << ((startShiftByte - idx) * 8);
    }

    context.stack[context.stackLength++] = bytes32(value);
  }

  uint private constant CONTEXT_TOKEN_ID = 0;
  uint private constant CONTEXT_TOKEN_OWNER = 1;
  uint private constant CONTEXT_BLOCK_TIMESTAMP = 2;
  uint private constant CONTEXT_ARWEAVE_CONTENT_API = 3;
  uint private constant CONTEXT_IPFS_CONTENT_API = 4;
  uint private constant CONTEXT_GENERATION = 5;
  uint private constant CONTEXT_INDEX = 6;


  // 2byte opcode to push well-known context data to the stack
  // byte 1 is the push codepoint,
  // byte 2 well-known context id
  function execPushContext(Context memory context, bytes32[] memory, bytes32[] memory) internal view {
    uint contextId = uint256(context.stack[context.stackLength-1]);

    if (contextId == CONTEXT_TOKEN_ID) {
      context.stack[context.stackLength-1] = bytes32(context.tokenId);
    } else if (contextId == CONTEXT_TOKEN_OWNER ) {
      context.stack[context.stackLength-1] = bytes32(uint256(uint160(context.owner)));
    } else if (contextId == CONTEXT_BLOCK_TIMESTAMP ) {
      // solhint-disable-next-line not-rely-on-time
      context.stack[context.stackLength-1] = bytes32(uint256(block.timestamp));
    } else if (contextId == CONTEXT_GENERATION) {
      context.stack[context.stackLength-1] = bytes32(uint(context.generation));
    } else if (contextId == CONTEXT_INDEX) {
      context.stack[context.stackLength-1] = bytes32(context.index);
    } else {
      revert('Unknown/unsupported context ID in push');
    }
  }

  // 1byte opcode to push the 32 bytes at the slot indicated by the top of the stack
  function execPushStorage(Context memory context, bytes32[] memory, bytes32[] memory) internal view {
    bytes32 stackTop = context.stack[context.stackLength - 1];
    context.stack[context.stackLength - 1] = StorageSlot.getBytes32Slot(stackTop).value;
  }

  // 1byte opcode to push the 32 bytes at the slot indicated by the top of the stack
  function execPushColumnar(Context memory context, bytes32[] memory, bytes32[] memory) internal view {
    require(context.stack.length > 1, 'stack underflow');
    bytes32 rawColumnSlot = context.stack[context.stackLength - 2];
    bytes32 columnSlot = bytes32(NamelessDataV1.getGenerationalSlot(uint(rawColumnSlot), context.generation));
    uint columnIndex = uint(context.stack[context.stackLength - 1]);
    context.stackLength -= 1;

    uint256 columnMetadata = StorageSlot.getUint256Slot(columnSlot).value;
    uint columnType = (columnMetadata >> 248) & 0xFF;

    if (columnType == NamelessDataV1.COLUMN_TYPE_UINT256) {
      uint value = NamelessDataV1.readUint256Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      context.stack[context.stackLength - 1] = bytes32(value);
    } else if (columnType == NamelessDataV1.COLUMN_TYPE_UINT128) {
      uint value = NamelessDataV1.readUint128Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      context.stack[context.stackLength - 1] = bytes32(value);
    } else if (columnType == NamelessDataV1.COLUMN_TYPE_UINT64) {
      uint value = NamelessDataV1.readUint64Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      context.stack[context.stackLength - 1] = bytes32(value);
    } else if (columnType == NamelessDataV1.COLUMN_TYPE_UINT32) {
      uint value = NamelessDataV1.readUint32Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      context.stack[context.stackLength - 1] = bytes32(value);
    } else if (columnType == NamelessDataV1.COLUMN_TYPE_UINT16) {
      uint value = NamelessDataV1.readUint16Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      context.stack[context.stackLength - 1] = bytes32(value);
    } else if (columnType == NamelessDataV1.COLUMN_TYPE_UINT8) {
      uint value = NamelessDataV1.readUint8Column(bytes32(uint256(columnSlot) + 1), columnIndex);
      context.stack[context.stackLength - 1] = bytes32(value);
    } else {
      revert('unknown or bad column type');
    }
  }

  function execPop(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    context.stackLength--;
  }

  function execDup(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    context.stack[context.stackLength] = context.stack[context.stackLength - 1];
    context.stackLength++;
  }

  function execSwap(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    (context.stack[context.stackLength - 1], context.stack[context.stackLength - 2]) = (context.stack[context.stackLength - 2], context.stack[context.stackLength - 1]);
  }

  function execAdd(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(a + b);
    context.stackLength--;
  }

  function execSub(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(a - b);
    context.stackLength--;
  }

  function execMul(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(a * b);
    context.stackLength--;
  }

  function execDiv(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(a / b);
    context.stackLength--;
  }

  function execMod(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(a % b);
    context.stackLength--;
  }

  function execJumpPos(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 offset = uint256(context.stack[context.stackLength - 1]);
    context.stackLength--;

    addCodeOffset(context, offset);
  }

  function execJumpNeg(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 offset = uint256(context.stack[context.stackLength - 1]);
    context.stackLength--;

    subCodeOffset(context, offset);
  }

  function execBrEZPos(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 value = uint256(context.stack[context.stackLength - 2]);
    uint256 offset = uint256(context.stack[context.stackLength - 1]);
    context.stackLength-=2;

    if (value == 0) {
      addCodeOffset(context, offset);
    }
  }

  function execBrEZNeg(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 value = uint256(context.stack[context.stackLength - 2]);
    uint256 offset = uint256(context.stack[context.stackLength - 1]);
    context.stackLength-=2;

    if (value == 0) {
      subCodeOffset(context, offset);
    }
  }

  function execSha3(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    bytes32 a = context.stack[context.stackLength - 1];
    context.stack[context.stackLength - 1] = keccak256(abi.encodePacked(a));
  }

  function execXor(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    bytes32 a = context.stack[context.stackLength - 2];
    bytes32 b = context.stack[context.stackLength - 1];
    context.stack[context.stackLength - 2] = a ^ b;
    context.stackLength--;
  }

  function execOr(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    bytes32 a = context.stack[context.stackLength - 2];
    bytes32 b = context.stack[context.stackLength - 1];
    context.stack[context.stackLength - 2] = a | b;
    context.stackLength--;
  }

  function execAnd(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    bytes32 a = context.stack[context.stackLength - 2];
    bytes32 b = context.stack[context.stackLength - 1];
    context.stack[context.stackLength - 2] = a & b;
    context.stackLength--;
  }

  function execGt(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(uint256(a > b ? 1 : 0));
    context.stackLength--;
  }

  function execGte(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(uint256(a >= b ? 1 : 0));
    context.stackLength--;
  }

  function execLt(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(uint256(a < b ? 1 : 0));
    context.stackLength--;
  }

  function execLte(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    uint256 a = uint256(context.stack[context.stackLength - 2]);
    uint256 b = uint256(context.stack[context.stackLength - 1]);
    context.stack[context.stackLength - 2] = bytes32(uint256(a <= b ? 1 : 0));
    context.stackLength--;
  }

  function execEq(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    bytes32 a = context.stack[context.stackLength - 2];
    bytes32 b = context.stack[context.stackLength - 1];
    context.stack[context.stackLength - 2] = bytes32(uint256(a == b ? 1 : 0));
    context.stackLength--;
  }

  function execNeq(Context memory context, bytes32[] memory, bytes32[] memory) internal pure {
    bytes32 a = context.stack[context.stackLength - 2];
    bytes32 b = context.stack[context.stackLength - 1];
    context.stack[context.stackLength - 2] = bytes32(uint256(a != b ? 1 : 0));
    context.stackLength--;
  }

  uint private constant OP_NOOP                = 0x00;
  uint private constant OP_WRITE               = 0x01;
  uint private constant OP_WRITE_CONTEXT       = 0x02;
  uint private constant OP_WRITE_COLUMNAR      = 0x04;
  uint private constant OP_PUSH_DATA           = 0x05;
  uint private constant OP_PUSH_STORAGE        = 0x06;
  uint private constant OP_PUSH_IMMEDIATE      = 0x07;
  uint private constant OP_PUSH_CONTEXT        = 0x08;
  uint private constant OP_PUSH_COLUMNAR       = 0x09;
  uint private constant OP_POP                 = 0x0a;
  uint private constant OP_DUP                 = 0x0b;
  uint private constant OP_SWAP                = 0x0c;
  uint private constant OP_ADD                 = 0x0d;
  uint private constant OP_SUB                 = 0x0e;
  uint private constant OP_MUL                 = 0x0f;
  uint private constant OP_DIV                 = 0x10;
  uint private constant OP_MOD                 = 0x11;
  uint private constant OP_JUMP_POS            = 0x12;
  uint private constant OP_JUMP_NEG            = 0x13;
  uint private constant OP_BRANCH_POS_EQ_ZERO  = 0x14;
  uint private constant OP_BRANCH_NEG_EQ_ZERO  = 0x15;
  uint private constant OP_SHA3                = 0x16;
  uint private constant OP_XOR                 = 0x17;
  uint private constant OP_OR                  = 0x18;
  uint private constant OP_AND                 = 0x19;
  uint private constant OP_GT                  = 0x1a;
  uint private constant OP_GTE                 = 0x1b;
  uint private constant OP_LT                  = 0x1c;
  uint private constant OP_LTE                 = 0x1d;
  uint private constant OP_EQ                  = 0x1e;
  uint private constant OP_NEQ                 = 0x1f;

  function incrementCodeOffset(Context memory context) internal pure {
    context.codeBufferOffset++;
    if (context.codeBufferOffset == 32) {
      context.codeBufferOffset = 0;
      context.codeBufferIndex++;
    }
  }

  function addCodeOffset(Context memory context, uint offset) internal pure {
    uint pc = (context.codeBufferIndex * 32) + context.codeBufferOffset;
    pc += offset;
    context.codeBufferOffset = pc % 32;
    context.codeBufferIndex = pc / 32;
  }

  function subCodeOffset(Context memory context, uint offset) internal pure {
    uint pc = (context.codeBufferIndex * 32) + context.codeBufferOffset;
    pc -= offset;
    context.codeBufferOffset = pc % 32;
    context.codeBufferIndex = pc / 32;
  }

  function execOne(Context memory context, bytes32[] memory dataSegment, bytes32[] memory codeSegment) internal view {
    uint nextOp = uint8(codeSegment[context.codeBufferIndex][context.codeBufferOffset]);

    incrementCodeOffset(context);

    if (nextOp == OP_NOOP) {
      //solhint-disable-previous-line no-empty-blocks
    } else if (nextOp == OP_WRITE) {
      execWrite(context, dataSegment, codeSegment);
    } else if (nextOp == OP_WRITE_CONTEXT) {
      execWriteContext(context, dataSegment, codeSegment);
    } else if (nextOp == OP_WRITE_COLUMNAR) {
      execWriteColumnar(context, dataSegment, codeSegment);
    } else if (nextOp == OP_PUSH_DATA) {
      execPushData(context, dataSegment, codeSegment);
    } else if (nextOp == OP_PUSH_STORAGE) {
      execPushStorage(context, dataSegment, codeSegment);
    } else if (nextOp == OP_PUSH_IMMEDIATE) {
      execPushImmediate(context, dataSegment, codeSegment);
    } else if (nextOp == OP_PUSH_CONTEXT) {
      execPushContext(context, dataSegment, codeSegment);
    } else if (nextOp == OP_PUSH_COLUMNAR) {
      execPushColumnar(context, dataSegment, codeSegment);
    } else if (nextOp == OP_POP) {
      execPop(context, dataSegment, codeSegment);
    } else if (nextOp == OP_DUP) {
      execDup(context, dataSegment, codeSegment);
    } else if (nextOp == OP_SWAP) {
      execSwap(context, dataSegment, codeSegment);
    } else if (nextOp == OP_ADD) {
      execAdd(context, dataSegment, codeSegment);
    } else if (nextOp == OP_SUB) {
      execSub(context, dataSegment, codeSegment);
    } else if (nextOp == OP_MUL) {
      execMul(context, dataSegment, codeSegment);
    } else if (nextOp == OP_DIV) {
      execDiv(context, dataSegment, codeSegment);
    } else if (nextOp == OP_MOD) {
      execMod(context, dataSegment, codeSegment);
    } else if (nextOp == OP_JUMP_POS) {
      execJumpPos(context, dataSegment, codeSegment);
    } else if (nextOp == OP_JUMP_NEG) {
      execJumpNeg(context, dataSegment, codeSegment);
    } else if (nextOp == OP_BRANCH_POS_EQ_ZERO) {
      execBrEZPos(context, dataSegment, codeSegment);
    } else if (nextOp == OP_BRANCH_NEG_EQ_ZERO) {
      execBrEZNeg(context, dataSegment, codeSegment);
    } else if (nextOp == OP_SHA3) {
      execSha3(context, dataSegment, codeSegment);
    } else if (nextOp == OP_XOR) {
      execXor(context, dataSegment, codeSegment);
    } else if (nextOp == OP_OR) {
      execOr(context, dataSegment, codeSegment);
    } else if (nextOp == OP_AND) {
      execAnd(context, dataSegment, codeSegment);
    } else if (nextOp == OP_GT) {
      execGt(context, dataSegment, codeSegment);
    } else if (nextOp == OP_GTE) {
      execGte(context, dataSegment, codeSegment);
    } else if (nextOp == OP_LT) {
      execLt(context, dataSegment, codeSegment);
    } else if (nextOp == OP_LTE) {
      execLte(context, dataSegment, codeSegment);
    } else if (nextOp == OP_EQ) {
      execEq(context, dataSegment, codeSegment);
    } else if (nextOp == OP_NEQ) {
      execNeq(context, dataSegment, codeSegment);
    } else {
      revert(string(abi.encodePacked('bad op code: ', Strings.toString(nextOp), ' next_pc: ', Strings.toString(context.codeBufferIndex), ',',  Strings.toString(context.codeBufferOffset))));
    }

    context.opsRetired++;

    if (/*context.opsRetired > 7 || */context.codeBufferIndex >= codeSegment.length) {
      context.done = true;
    }
  }

  function interpolateTemplate(uint256 tokenId, uint32 generation, uint index, address owner, string memory arweaveContentApi, string memory ipfsContentApi, bytes32[] memory dataSegment, bytes32[] memory codeSegment) internal view returns (bytes memory) {
    Context memory context;
    context.output = new bytes(0xFFFF);
    context.tokenId = tokenId;
    context.generation = generation;
    context.index = index;
    context.owner = owner;
    context.arweaveContentApi = arweaveContentApi;
    context.ipfsContentApi = ipfsContentApi;
    context.outOffset = 0;

    while (!context.done) {
      execOne(context, dataSegment, codeSegment);
    }

    bytes memory result = context.output;
    uint resultLen = context.outOffset;

    //solhint-disable-next-line no-inline-assembly
    assembly {
      mstore(result, resultLen)
    }

    return result;
  }

  function makeJson( uint256 tokenId, uint32 generation, uint index, address owner, string memory arweaveContentApi, string memory ipfsContentApi, bytes32[] memory dataSegment, bytes32[] memory codeSegment ) public view returns (string memory) {
    bytes memory metadata = interpolateTemplate(tokenId, generation, index, owner, arweaveContentApi, ipfsContentApi, dataSegment, codeSegment);
    return string(metadata);
  }

  function makeDataURI( string memory uriBase, uint256 tokenId, uint32 generation, uint index, address owner, string memory arweaveContentApi, string memory ipfsContentApi, bytes32[] memory dataSegment, bytes32[] memory codeSegment ) public view returns (string memory) {
    bytes memory metadata = interpolateTemplate(tokenId, generation, index, owner, arweaveContentApi, ipfsContentApi, dataSegment, codeSegment);
    return string(abi.encodePacked(uriBase,Base64.encode(metadata)));
  }
}
