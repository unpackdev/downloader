// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.0;

contract Verifier  {

    enum ValidationState {
      LOOKING_FOR_OPEN_TAG_OPEN_BRACKET,
      LOOKING_FOR_OPEN_TAG_CLOSE_BRACKET,
      LOOKING_FOR_OPEN_TAG_CLOSE_BRACKET_EXCLUSIVE,
      LOOKING_FOR_CLOSE_TAG_OPEN_BRACKET,
      LOOKING_FOR_CLOSE_TAG_SLASH,
      LOOKING_FOR_CLOSE_TAG_CLOSE_BRACKET,
      LOOKING_FOR_CLOSE_QUOTE
    }

    struct ValidationStackFrame {
      ValidationState state;
      uint            index;
    }

    struct ResponseCode {
      bool   valid;
      string reason;
    }

    function validate(bytes memory layer) public pure returns (ResponseCode memory) {
      ValidationStackFrame[] memory stack = new ValidationStackFrame[](10);
      uint16                        index = 0;

      stack[0] = ValidationStackFrame({state: ValidationState.LOOKING_FOR_OPEN_TAG_OPEN_BRACKET, index: 0});

      for (uint i=0;i<layer.length;i++) {
        if (stack[index].state == ValidationState.LOOKING_FOR_OPEN_TAG_OPEN_BRACKET) {
          if (layer[i] != 0x3c)          return ResponseCode({valid: false, reason: "Expecting '<'"});
          if (index + 1 >= stack.length) return ResponseCode({valid: false, reason: "Stack space exceeded"});

          stack[++index] = ValidationStackFrame({state: ValidationState.LOOKING_FOR_OPEN_TAG_CLOSE_BRACKET, index: i+1});
        } else if (stack[index].state == ValidationState.LOOKING_FOR_OPEN_TAG_CLOSE_BRACKET) {
          if (layer[i] == 0x2f) { // '/'
            stack[index] = ValidationStackFrame({state: ValidationState.LOOKING_FOR_OPEN_TAG_CLOSE_BRACKET_EXCLUSIVE, index: i});
          } else if (layer[i] == 0x22) { // '"'
            if (index + 1 >= stack.length) return ResponseCode({valid: false, reason: "Stack space exceeded"});
            stack[++index] = ValidationStackFrame({state: ValidationState.LOOKING_FOR_CLOSE_QUOTE, index: i});
          } else if (layer[i] == 0x3e) { // '>'
            stack[index] = ValidationStackFrame({state: ValidationState.LOOKING_FOR_CLOSE_TAG_OPEN_BRACKET, index: stack[index].index});
          } else if (!((layer[i] >= 0x30 && layer[i] <= 0x39) || (layer[i] >= 0x41 && layer[i] <= 0x5a) || (layer[i] >= 0x61 && layer[i] <= 0x7a) || (layer[i] == 0x5f) || (layer[i] == 0x3d) || (layer[i] == 0x20) || (layer[i] == 0x2d))) {
            return ResponseCode({valid: false, reason: string(abi.encodePacked("Expecting '0-9', 'a-zA-Z', '=', '-', or ' ' but got: ", layer[i]))});
          }
        } else if (stack[index].state == ValidationState.LOOKING_FOR_OPEN_TAG_CLOSE_BRACKET_EXCLUSIVE) {
          if (layer[i] != 0x3e) return ResponseCode({valid: false, reason: "Expecting '>'"});
          index--;
        } else if (stack[index].state == ValidationState.LOOKING_FOR_CLOSE_TAG_OPEN_BRACKET) {
          if (layer[i] != 0x3c) return ResponseCode({valid: false, reason: "Expecting '<'"});
          stack[index] = ValidationStackFrame({state: ValidationState.LOOKING_FOR_CLOSE_TAG_SLASH, index: stack[index].index});
        } else if (stack[index].state == ValidationState.LOOKING_FOR_CLOSE_TAG_SLASH) {
          if (layer[i] == 0x2f) { // '/'
            stack[index] = ValidationStackFrame({state: ValidationState.LOOKING_FOR_CLOSE_TAG_CLOSE_BRACKET, index: i + 1 - stack[index].index});
          } else {
            if (!((layer[i] >= 0x41 && layer[i] <= 0x5a) || (layer[i] >= 0x61 && layer[i] <= 0x7a))) return ResponseCode({valid: false, reason: "Expecting a-zA-Z"});
            if (index + 1 >= stack.length)                                                           return ResponseCode({valid: false, reason: "Stack space exceeded"});

            stack[index]   = ValidationStackFrame({state: ValidationState.LOOKING_FOR_CLOSE_TAG_OPEN_BRACKET, index: stack[index].index});
            stack[++index] = ValidationStackFrame({state: ValidationState.LOOKING_FOR_OPEN_TAG_CLOSE_BRACKET, index: i});
          }
        } else if (stack[index].state == ValidationState.LOOKING_FOR_CLOSE_TAG_CLOSE_BRACKET) {
          if (layer[i] == 0x3e) { // '>'
            index--;
          } else if (layer[i] != layer[i - stack[index].index]) {
            return ResponseCode({valid: false, reason: string(abi.encodePacked("Expecting a-zA-Z to match: ", layer[i - stack[index].index]))});
          }
        } else if (stack[index].state == ValidationState.LOOKING_FOR_CLOSE_QUOTE) {
          if (layer[i] == 0x22) { // '"'
            index--; 
          } else if (!(layer[i] >= 0x20 && layer[i] <= 0x7e) || layer[i] == 0x5c) {
            return ResponseCode({valid: false, reason: string(abi.encodePacked("Expecting ascii 0x20-0x7e, but got: ", layer[i]))});
          }
        }
      }

      if (index != 0) return ResponseCode({valid: false, reason: "Ended with non-zero index"});
      else            return ResponseCode({valid: true, reason: ""});
    }

}