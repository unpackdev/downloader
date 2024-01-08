// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./base64.sol";
library Meta {
  function generate(uint24[] memory chars) internal pure returns (string memory svg) {
    bytes memory utf16;
    bytes memory utf8;
    for(uint i=0; i<chars.length; i++) {
      uint24 char = chars[i];
      // 1. utf8
      bytes memory h = _toString(char, true); 
      utf8 = abi.encodePacked(utf8, abi.encodePacked("&#x", h, ";"));
      // 2. utf16
      if (char >= 0x10000) {
        // surrogate pair => astral
        utf16 = abi.encodePacked(utf16, abi.encodePacked(
          "\\u", _toString((char-0x10000)/0x400+0xD800, true),
          "\\u", _toString((char-0x10000)%0x400+0xDC00, true)
        ));
      } else {
        utf16 = abi.encodePacked(utf16, abi.encodePacked("\\u", h));
      }
    }
    uint24 size = uint24(chars.length);
    uint24 dimension;
    if (size > 30) {
      dimension = 10 * size;
    } else if (size > 20) {
      dimension = 8 * size + 60;
    } else if (size > 10) {
      dimension = 5 * size + 110;
    } else if (size > 5) {
      dimension = 2 * size + 140;
    } else {
      dimension = 150;
    }
    return string(
      // use utf16 for JSON, utf8 for HTML (SVG)
      abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(abi.encodePacked( '{"name":"', utf16, '", "image": "', _image(utf8, string(_toString(dimension, false))), '"}'))
      )
    );
  }
  function _image(bytes memory utf8, string memory dimension) internal pure returns (string memory svg) {
    return string(
      abi.encodePacked(
        "data:image/svg+xml;base64,",
        Base64.encode(
          abi.encodePacked(
            "<svg style='background:#191919' width='1000' height='1000' viewBox='0 0 ",
            dimension,
            " ",
            dimension,
            "' xmlns='http://www.w3.org/2000/svg'><text fill='#fff' x='50%' y='50%' dominant-baseline='central' text-anchor='middle' style='font-family: sans-serif, arial; font-size:12px;'>",
            utf8,
            "</text></svg>"
          )
        )
      )
    );
  }
  function _toString(uint24 i, bool isHex) internal pure returns (bytes memory) {
    if (i == 0) return "0000";
    uint j = i;
    uint length;
    while (j != 0) {
      length++;
      if (isHex) j = j>>4;
      else j = j/10;
    }
    uint mask = 15;
    bytes memory bstr = new bytes(length);
    uint k = length;
    while (i != 0) {
      if (isHex) {
        uint curr = (i & mask);
        bstr[--k] = curr > 9 ?  bytes1(uint8(55 + curr)) : bytes1(uint8(48 + curr));
        i = i>>4;
      } else {
        k = k-1;
        bstr[k] = bytes1(48 + uint8(i - i / 10 * 10));
        i = i/10;
      }
    }
    if (isHex) {
      string[6] memory zeros = ["000", "00", "0", "", "", ""];
      return abi.encodePacked(zeros[bstr.length-1], bstr);
    } else {
      return bstr;
    }
  }
}
