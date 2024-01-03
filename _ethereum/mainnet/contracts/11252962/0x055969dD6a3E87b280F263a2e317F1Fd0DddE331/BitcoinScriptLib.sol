// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./LELib.sol";
import "./SliceLib.sol";
import "./MemcpyLib.sol";

library BitcoinScriptLib {
  using LELib for *;
  using SliceLib for *;
  struct Script {
    bytes buffer;
    uint256 len;
  }
  function newScript(uint256 hint) internal pure returns (Script memory script) {
    script.buffer = new bytes(hint);
  }
  function newScript() internal pure returns (Script memory) {
    return newScript(0x400);
  }
  // push value
  uint8 constant _OP_FALSE = 0;
  uint8 constant _OP_0 = 0;
  uint8 constant _OP_PUSHDATA1 = 76;
  uint8 constant _OP_PUSHDATA2 = 77;
  uint8 constant _OP_PUSHDATA4 = 78;
  uint8 constant _OP_1NEGATE = 79;
  uint8 constant _OP_RESERVED = 80;
  uint8 constant _OP_TRUE = 81;
  uint8 constant _OP_1 = 81;
  uint8 constant _OP_2 = 82;
  uint8 constant _OP_3 = 83;
  uint8 constant _OP_4 = 84;
  uint8 constant _OP_5 = 85;
  uint8 constant _OP_6 = 86;
  uint8 constant _OP_7 = 87;
  uint8 constant _OP_8 = 88;
  uint8 constant _OP_9 = 89;
  uint8 constant _OP_10 = 90;
  uint8 constant _OP_11 = 91;
  uint8 constant _OP_12 = 92;
  uint8 constant _OP_13 = 93;
  uint8 constant _OP_14 = 94;
  uint8 constant _OP_15 = 95;
  uint8 constant _OP_16 = 96;

  // control
  uint8 constant _OP_NOP = 97;
  uint8 constant _OP_VER = 98;
  uint8 constant _OP_IF = 99;
  uint8 constant _OP_NOTIF = 100;
  uint8 constant _OP_VERIF = 101;
  uint8 constant _OP_VERNOTIF = 102;
  uint8 constant _OP_ELSE = 103;
  uint8 constant _OP_ENDIF = 104;
  uint8 constant _OP_VERIFY = 105;
  uint8 constant _OP_RETURN = 106;
  // stack ops
  uint8 constant _OP_TOALTSTACK = 107;
  uint8 constant _OP_FROMALTSTACK = 108;
  uint8 constant _OP_2DROP = 109;
  uint8 constant _OP_2DUP = 110;
  uint8 constant _OP_3DUP = 111;
  uint8 constant _OP_2OVER = 112;
  uint8 constant _OP_2ROT = 113;
  uint8 constant _OP_2SWAP = 114;
  uint8 constant _OP_IFDUP = 115;
  uint8 constant _OP_DEPTH = 116;
  uint8 constant _OP_DROP = 117;
  uint8 constant _OP_DUP = 118;
  uint8 constant _OP_NIP = 119;
  uint8 constant _OP_OVER = 120;
  uint8 constant _OP_PICK = 121;
  uint8 constant _OP_ROLL = 122;
  uint8 constant _OP_ROT = 123;
  uint8 constant _OP_SWAP = 124;
  uint8 constant _OP_TUCK = 125;

  // splice ops
  uint8 constant _OP_CAT = 126;
  uint8 constant _OP_SUBSTR = 127;
  uint8 constant _OP_LEFT = 128;
  uint8 constant _OP_RIGHT = 129;
  uint8 constant _OP_SIZE = 130;

  // bit logic
  uint8 constant _OP_INVERT = 131;
  uint8 constant _OP_AND = 132;
  uint8 constant _OP_OR = 133;
  uint8 constant _OP_XOR = 134;
  uint8 constant _OP_EQUAL = 135;
  uint8 constant _OP_EQUALVERIFY = 136;
  uint8 constant _OP_RESERVED1 = 137;
  uint8 constant _OP_RESERVED2 = 138;

  // numeric
  uint8 constant _OP_1ADD = 139;
  uint8 constant _OP_1SUB = 140;
  uint8 constant _OP_2MUL = 141;
  uint8 constant _OP_2DIV = 142;
  uint8 constant _OP_NEGATE = 143;
  uint8 constant _OP_ABS = 144;
  uint8 constant _OP_NOT = 145;
  uint8 constant _OP_0NOTEQUAL = 146;

  uint8 constant _OP_ADD = 147;
  uint8 constant _OP_SUB = 148;
  uint8 constant _OP_MUL = 149;
  uint8 constant _OP_DIV = 150;
  uint8 constant _OP_MOD = 151;
  uint8 constant _OP_LSHIFT = 152;
  uint8 constant _OP_RSHIFT = 153;

  uint8 constant _OP_BOOLAND = 154;
  uint8 constant _OP_BOOLOR = 155;
  uint8 constant _OP_NUMEQUAL = 156;
  uint8 constant _OP_NUMEQUALVERIFY = 157;
  uint8 constant _OP_NUMNOTEQUAL = 158;
  uint8 constant _OP_LESSTHAN = 159;
  uint8 constant _OP_GREATERTHAN = 160;
  uint8 constant _OP_LESSTHANOREQUAL = 161;
  uint8 constant _OP_GREATERTHANOREQUAL = 162;
  uint8 constant _OP_MIN = 163;
  uint8 constant _OP_MAX = 164;

  uint8 constant _OP_WITHIN = 165;

  // crypto
  uint8 constant _OP_RIPEMD160 = 166;
  uint8 constant _OP_SHA1 = 167;
  uint8 constant _OP_SHA256 = 168;
  uint8 constant _OP_HASH160 = 169;
  uint8 constant _OP_HASH256 = 170;
  uint8 constant _OP_CODESEPARATOR = 171;
  uint8 constant _OP_CHECKSIG = 172;
  uint8 constant _OP_CHECKSIGVERIFY = 173;
  uint8 constant _OP_CHECKMULTISIG = 174;
  uint8 constant _OP_CHECKMULTISIGVERIFY = 175;

  uint8 constant _OP_CHECKLOCKTIMEVERIFY = 177;
  uint8 constant _OP_CHECKSEQUENCEVERIFY = 178;

  // expansion
  uint8 constant _OP_NOP1 = 176;
  uint8 constant _OP_NOP2 = 177;
  uint8 constant _OP_NOP3 = 178;
  uint8 constant _OP_NOP4 = 179;
  uint8 constant _OP_NOP5 = 180;
  uint8 constant _OP_NOP6 = 181;
  uint8 constant _OP_NOP7 = 182;
  uint8 constant _OP_NOP8 = 183;
  uint8 constant _OP_NOP9 = 184;
  uint8 constant _OP_NOP10 = 185;

  // template matching params
  uint8 constant _OP_PUBKEYHASH = 253;
  uint8 constant _OP_PUBKEY = 254;
  uint8 constant _OP_INVALIDOPCODE = 255;
  function OP_FALSE() internal pure returns (uint8) {
    return _OP_FALSE;
  }
  function OP_0() internal pure returns (uint8) {
    return _OP_0;
  }
  function OP_PUSHDATA1() internal pure returns (uint8) {
    return _OP_PUSHDATA1;
  }
  function OP_PUSHDATA2() internal pure returns (uint8) {
    return _OP_PUSHDATA2;
  }
  function OP_PUSHDATA4() internal pure returns (uint8) {
    return _OP_PUSHDATA4;
  }
  function OP_1NEGATE() internal pure returns (uint8) {
    return _OP_1NEGATE;
  }
  function OP_RESERVED() internal pure returns (uint8) {
    return _OP_RESERVED;
  }
  function OP_TRUE() internal pure returns (uint8) {
    return _OP_TRUE;
  }
  function OP_1() internal pure returns (uint8) {
    return _OP_1;
  }
  function OP_2() internal pure returns (uint8) {
    return _OP_2;
  }
  function OP_3() internal pure returns (uint8) {
    return _OP_3;
  }
  function OP_4() internal pure returns (uint8) {
    return _OP_4;
  }
  function OP_5() internal pure returns (uint8) {
    return _OP_5;
  }
  function OP_6() internal pure returns (uint8) {
    return _OP_6;
  }
  function OP_7() internal pure returns (uint8) {
    return _OP_7;
  }
  function OP_8() internal pure returns (uint8) {
    return _OP_8;
  }
  function OP_9() internal pure returns (uint8) {
    return _OP_9;
  }
  function OP_10() internal pure returns (uint8) {
    return _OP_10;
  }
  function OP_11() internal pure returns (uint8) {
    return _OP_11;
  }
  function OP_12() internal pure returns (uint8) {
    return _OP_12;
  }
  function OP_13() internal pure returns (uint8) {
    return _OP_13;
  }
  function OP_14() internal pure returns (uint8) {
    return _OP_14;
  }
  function OP_15() internal pure returns (uint8) {
    return _OP_15;
  }
  function OP_16() internal pure returns (uint8) {
    return _OP_16;
  }
  function OP_NOP() internal pure returns (uint8) {
    return _OP_NOP;
  }
  function OP_VER() internal pure returns (uint8) {
    return _OP_VER;
  }
  function OP_IF() internal pure returns (uint8) {
    return _OP_IF;
  }
  function OP_NOTIF() internal pure returns (uint8) {
    return _OP_NOTIF;
  }
  function OP_VERIF() internal pure returns (uint8) {
    return _OP_VERIF;
  }
  function OP_VERNOTIF() internal pure returns (uint8) {
    return _OP_VERNOTIF;
  }
  function OP_ELSE() internal pure returns (uint8) {
    return _OP_ELSE;
  }
  function OP_ENDIF() internal pure returns (uint8) {
    return _OP_ENDIF;
  }
  function OP_VERIFY() internal pure returns (uint8) {
    return _OP_VERIFY;
  }
  function OP_RETURN() internal pure returns (uint8) {
    return _OP_RETURN;
  }
  function OP_TOALTSTACK() internal pure returns (uint8) {
    return _OP_TOALTSTACK;
  }
  function OP_FROMALTSTACK() internal pure returns (uint8) {
    return _OP_FROMALTSTACK;
  }
  function OP_2DROP() internal pure returns (uint8) {
    return _OP_2DROP;
  }
  function OP_2DUP() internal pure returns (uint8) {
    return _OP_2DUP;
  }
  function OP_3DUP() internal pure returns (uint8) {
    return _OP_3DUP;
  }
  function OP_2OVER() internal pure returns (uint8) {
    return _OP_2OVER;
  }
  function OP_2ROT() internal pure returns (uint8) {
    return _OP_2ROT;
  }
  function OP_2SWAP() internal pure returns (uint8) {
    return _OP_2SWAP;
  }
  function OP_IFDUP() internal pure returns (uint8) {
    return _OP_IFDUP;
  }
  function OP_DEPTH() internal pure returns (uint8) {
    return _OP_DEPTH;
  }
  function OP_DROP() internal pure returns (uint8) {
    return _OP_DROP;
  }
  function OP_DUP() internal pure returns (uint8) {
    return _OP_DUP;
  }
  function OP_NIP() internal pure returns (uint8) {
    return _OP_NIP;
  }
  function OP_OVER() internal pure returns (uint8) {
    return _OP_OVER;
  }
  function OP_PICK() internal pure returns (uint8) {
    return _OP_PICK;
  }
  function OP_ROLL() internal pure returns (uint8) {
    return _OP_ROLL;
  }
  function OP_ROT() internal pure returns (uint8) {
    return _OP_ROT;
  }
  function OP_SWAP() internal pure returns (uint8) {
    return _OP_SWAP;
  }
  function OP_TUCK() internal pure returns (uint8) {
    return _OP_TUCK;
  }
  function OP_CAT() internal pure returns (uint8) {
    return _OP_CAT;
  }
  function OP_SUBSTR() internal pure returns (uint8) {
    return _OP_SUBSTR;
  }
  function OP_LEFT() internal pure returns (uint8) {
    return _OP_LEFT;
  }
  function OP_RIGHT() internal pure returns (uint8) {
    return _OP_RIGHT;
  }
  function OP_SIZE() internal pure returns (uint8) {
    return _OP_SIZE;
  }
  function OP_INVERT() internal pure returns (uint8) {
    return _OP_INVERT;
  }
  function OP_AND() internal pure returns (uint8) {
    return _OP_AND;
  }
  function OP_OR() internal pure returns (uint8) {
    return _OP_OR;
  }
  function OP_XOR() internal pure returns (uint8) {
    return _OP_XOR;
  }
  function OP_EQUAL() internal pure returns (uint8) {
    return _OP_EQUAL;
  }
  function OP_EQUALVERIFY() internal pure returns (uint8) {
    return _OP_EQUALVERIFY;
  }
  function OP_RESERVED1() internal pure returns (uint8) {
    return _OP_RESERVED1;
  }
  function OP_RESERVED2() internal pure returns (uint8) {
    return _OP_RESERVED2;
  }
  function OP_1ADD() internal pure returns (uint8) {
    return _OP_1ADD;
  }
  function OP_1SUB() internal pure returns (uint8) {
    return _OP_1SUB;
  }
  function OP_2MUL() internal pure returns (uint8) {
    return _OP_2MUL;
  }
  function OP_2DIV() internal pure returns (uint8) {
    return _OP_2DIV;
  }
  function OP_NEGATE() internal pure returns (uint8) {
    return _OP_NEGATE;
  }
  function OP_ABS() internal pure returns (uint8) {
    return _OP_ABS;
  }
  function OP_NOT() internal pure returns (uint8) {
    return _OP_NOT;
  }
  function OP_0NOTEQUAL() internal pure returns (uint8) {
    return _OP_0NOTEQUAL;
  }
  function OP_ADD() internal pure returns (uint8) {
    return _OP_ADD;
  }
  function OP_SUB() internal pure returns (uint8) {
    return _OP_SUB;
  }
  function OP_MUL() internal pure returns (uint8) {
    return _OP_MUL;
  }
  function OP_DIV() internal pure returns (uint8) {
    return _OP_DIV;
  }
  function OP_MOD() internal pure returns (uint8) {
    return _OP_MOD;
  }
  function OP_LSHIFT() internal pure returns (uint8) {
    return _OP_LSHIFT;
  }
  function OP_RSHIFT() internal pure returns (uint8) {
    return _OP_RSHIFT;
  }
  function OP_BOOLAND() internal pure returns (uint8) {
    return _OP_BOOLAND;
  }
  function OP_BOOLOR() internal pure returns (uint8) {
    return _OP_BOOLOR;
  }
  function OP_NUMEQUAL() internal pure returns (uint8) {
    return _OP_NUMEQUAL;
  }
  function OP_NUMEQUALVERIFY() internal pure returns (uint8) {
    return _OP_NUMEQUALVERIFY;
  }
  function OP_NUMNOTEQUAL() internal pure returns (uint8) {
    return _OP_NUMNOTEQUAL;
  }
  function OP_LESSTHAN() internal pure returns (uint8) {
    return _OP_LESSTHAN;
  }
  function OP_GREATERTHAN() internal pure returns (uint8) {
    return _OP_GREATERTHAN;
  }
  function OP_LESSTHANOREQUAL() internal pure returns (uint8) {
    return _OP_LESSTHANOREQUAL;
  }
  function OP_GREATERTHANOREQUAL() internal pure returns (uint8) {
    return _OP_GREATERTHANOREQUAL;
  }
  function OP_MIN() internal pure returns (uint8) {
    return _OP_MIN;
  }
  function OP_MAX() internal pure returns (uint8) {
    return _OP_MAX;
  }
  function OP_WITHIN() internal pure returns (uint8) {
    return _OP_WITHIN;
  }
  function OP_RIPEMD160() internal pure returns (uint8) {
    return _OP_RIPEMD160;
  }
  function OP_SHA1() internal pure returns (uint8) {
    return _OP_SHA1;
  }
  function OP_SHA256() internal pure returns (uint8) {
    return _OP_SHA256;
  }
  function OP_HASH160() internal pure returns (uint8) {
    return _OP_HASH160;
  }
  function OP_HASH256() internal pure returns (uint8) {
    return _OP_HASH256;
  }
  function OP_CODESEPARATOR() internal pure returns (uint8) {
    return _OP_CODESEPARATOR;
  }
  function OP_CHECKSIG() internal pure returns (uint8) {
    return _OP_CHECKSIG;
  }
  function OP_CHECKSIGVERIFY() internal pure returns (uint8) {
    return _OP_CHECKSIGVERIFY;
  }
  function OP_CHECKMULTISIG() internal pure returns (uint8) {
    return _OP_CHECKMULTISIG;
  }
  function OP_CHECKMULTISIGVERIFY() internal pure returns (uint8) {
    return _OP_CHECKMULTISIGVERIFY;
  }
  function OP_CHECKLOCKTIMEVERIFY() internal pure returns (uint8) {
    return _OP_CHECKLOCKTIMEVERIFY;
  }
  function OP_CHECKSEQUENCEVERIFY() internal pure returns (uint8) {
    return _OP_CHECKSEQUENCEVERIFY;
  }
  function OP_NOP1() internal pure returns (uint8) {
    return _OP_NOP1;
  }
  function OP_NOP2() internal pure returns (uint8) {
    return _OP_NOP2;
  }
  function OP_NOP3() internal pure returns (uint8) {
    return _OP_NOP3;
  }
  function OP_NOP4() internal pure returns (uint8) {
    return _OP_NOP4;
  }
  function OP_NOP5() internal pure returns (uint8) {
    return _OP_NOP5;
  }
  function OP_NOP6() internal pure returns (uint8) {
    return _OP_NOP6;
  }
  function OP_NOP7() internal pure returns (uint8) {
    return _OP_NOP7;
  }
  function OP_NOP8() internal pure returns (uint8) {
    return _OP_NOP8;
  }
  function OP_NOP9() internal pure returns (uint8) {
    return _OP_NOP9;
  }
  function OP_NOP10() internal pure returns (uint8) {
    return _OP_NOP10;
  }
  function OP_PUBKEYHASH() internal pure returns (uint8) {
    return _OP_PUBKEYHASH;
  }
  function OP_PUBKEY() internal pure returns (uint8) {
    return _OP_PUBKEY;
  }
  function OP_INVALIDOPCODE() internal pure returns (uint8) {
    return _OP_INVALIDOPCODE;
  }
  function _maybeRealloc(Script memory script, uint256 size) internal pure {
    if (script.len + size > script.buffer.length) {
      _realloc(script, script.buffer.length << 0x1);
    }
  }
  function _realloc(Script memory script, uint256 newLength) internal pure {
    bytes memory newBuffer = new bytes(newLength);
    bytes memory buffer = script.buffer;
    bytes32 newPtr;
    bytes32 ptr;
    assembly {
      newPtr := add(0x20, newBuffer)
      ptr := add(0x20, buffer)
    }
    MemcpyLib.memcpy(newPtr, ptr, script.len);
    script.buffer = newBuffer;
  }
  function addScript(Script memory script, uint8 op) internal pure returns (Script memory) {
    _maybeRealloc(script, 0x1);
    script.buffer[op] = byte(op);
    script.len++;
  } 
  function addScript(Script memory script, bytes memory buffer) internal pure returns (Script memory) {
    uint256 length = buffer.length;
    uint256 sz;
    bytes memory lengthBuffer;
    uint256 lenPtr;
    uint256 ptr;
    uint256 newPtr;
    byte op; 
    if (length < 0x100) {
      lengthBuffer = new bytes(1);
      sz = 1;
      op = byte(bytes1(_OP_PUSHDATA1));
      lengthBuffer[0] = byte(uint8(length));
    } else if (length < 0x10000) {
      lengthBuffer = uint16(length).toLE16();
      sz = 2;
      op = byte(bytes1(_OP_PUSHDATA2));
    } else if (length < 0x100000000) {
      lengthBuffer = uint32(length).toLE32();
      sz = 4;
      op = byte(bytes1(_OP_PUSHDATA4));
    } else revert("script pushdata overflow");
    _maybeRealloc(script, sz + 1 + buffer.length);
    bytes memory scriptBuffer = script.buffer;
    scriptBuffer[script.len] = op;
    assembly {
      lenPtr := add(0x20, lengthBuffer)
      ptr := add(0x21, scriptBuffer)
      newPtr := add(0x20, buffer)
    }
    MemcpyLib.memcpy(bytes32(ptr), bytes32(newPtr), sz);
    MemcpyLib.memcpy(bytes32(ptr + sz), bytes32(newPtr), buffer.length);
    return script;
  }
  function toBuffer(Script memory script) internal pure returns (bytes memory buffer) {
    buffer = script.buffer.toSlice(0, script.len).copy();
  }
  function hashBuffer(Script memory script) internal pure returns (bytes memory result) {
    bytes20 word = ripemd160(abi.encodePacked(keccak256(toBuffer(script))));
    result = new bytes(20);
    assembly {
      mstore(add(0x20, result), word)
    }
  }
  function toScriptHashOut(Script memory script) internal pure returns (Script memory output) {
    output = newScript(24);
    addScript(output, _OP_HASH160);
    addScript(output, hashBuffer(script));
    addScript(output, _OP_EQUAL);
  }
  function toAddress(Script memory script, bool isTestnet) internal pure returns (bytes memory buffer) {
    buffer = new bytes(21);
    buffer[0] = byte(uint8(isTestnet ? 0xc4 : 0x05));
    bytes memory scriptHash = hashBuffer(script);
    assembly {
      mstore(add(buffer, 0x21), mload(add(0x20, scriptHash)))
    }
  }
  function addressToBytes(address input) internal pure returns (bytes memory buffer) {
    buffer = new bytes(20);
    bytes20 word = bytes20(uint160(input));
    assembly {
      mstore(add(0x20, buffer), word)
    }
  }
  function bytes32ToBytes(bytes32 input) internal pure returns (bytes memory buffer) {
    buffer = new bytes(32);
    assembly {
      mstore(add(0x20, buffer), input)
    }
  }
  function assembleMintScript(bytes32 gHash, address mpkh) internal pure returns (Script memory script) {
    script = newScript(0x3d);
    addScript(script, bytes32ToBytes(gHash));
    addScript(script, _OP_DROP);
    addScript(script, _OP_DUP);
    addScript(script, _OP_HASH160);
    addScript(script, addressToBytes(mpkh));
    addScript(script, _OP_EQUALVERIFY);
    addScript(script, _OP_CHECKSIG);
    return toScriptHashOut(script);
  }
}
