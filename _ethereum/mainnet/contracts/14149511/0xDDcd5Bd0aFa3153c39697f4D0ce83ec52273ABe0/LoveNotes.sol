// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

// import "./console.sol";

contract LoveNotes is ERC721, Ownable {
  using Counters for Counters.Counter;

  struct Note {
    string[] note;
    uint256 background;
    uint256 fontSize;
    uint256 margin;
    uint256 marginTop;
    uint256 textAlign;
  }

  Counters.Counter public noteCount;
  bool private isOpen;
  bool private isFrozen;
  uint256 private price;
  uint256 private maxNumber;
  mapping(uint256 => Note) private notes;

  constructor() ERC721('LoveNotes', 'LOVE') {
    isOpen = false;
    isFrozen = false;
  }

  function love(
    string[] memory note,
    uint256 background,
    uint256 fontSize,
    uint256 margin,
    uint256 marginTop,
    uint256 textAlign
  ) public payable {
    require(isOpen, 'is open');
    require(msg.value >= price, 'price wrong');
    uint256 tokenId = noteCount.current();
    require(tokenId < maxNumber, 'too many');
    notes[tokenId] = Note(
      note,
      background,
      fontSize,
      margin,
      marginTop,
      textAlign
    );
    noteCount.increment();
    _safeMint(msg.sender, tokenId);
  }

  function setPrice(
    bool _isOpen,
    uint256 _maxNumber,
    uint256 _price
  ) public onlyOwner {
    require(!isFrozen, 'is frozen');
    isOpen = _isOpen;
    maxNumber = _maxNumber;
    price = _price;
  }

  function freeze() public onlyOwner {
    isFrozen = true;
  }

  function withdrawAll() public onlyOwner {
    require(payable(msg.sender).send(address(this).balance), '1');
  }

  function preview(
    string[] memory note,
    uint256 background,
    uint256 fontSize,
    uint256 margin,
    uint256 marginTop,
    uint256 textAlign
  ) public pure returns (string memory) {
    string memory backgroundS;
    if (background == 0) {
      backgroundS = '<path d="M312 120.519c-2-74-104-92.5-137-23.5-33-69-135-50.5-137 23.5 0 81 104 151 137 175.5 33-24.5 137-98.5 137-175.5z" stroke="#ffebeb" stroke-width="14"/>';
    } else if (background == 1) {
      backgroundS = '<g fill="#fff"><path d="M0 0h350v350H0z"/><path d="M21.5 21.5h307v307h-307z"/></g><path stroke="#fff2f3" stroke-width="3" d="M21.5 21.5h307v307h-307z"/>';
    } else if (background == 2) {
      backgroundS = '<defs><path id="A" d="M54.343 13.193C53.946-1.484 33.716-5.153 27.171 8.532 20.627-5.153.397-1.484 0 13.193 0 29.353 20.627 43.141 27.171 48c6.545-4.859 27.171-19.536 27.171-34.807z" stroke="#ffedee" stroke-width="5"/></defs><g id="B"><use href="#A" transform="matrix(.913545 -.406737 .406737 .913545 62 3)"/><use href="#A" transform="matrix(.913545 .406737 -.406737 .913545 163 -18)"/><use href="#A" transform="matrix(.913545 -.406737 .406737 .913545 230 6)"/></g><g id="C"><use href="#A" transform="matrix(.913545 .406737 -.406737 .913545 -1 24)"/><use href="#A" transform="matrix(.913545 -.406737 .406737 .913545 -15 128)"/><use href="#A" transform="matrix(.913545 .406737 -.406737 .913545 -1 190)"/><use href="#A" transform="matrix(.913545 -.406737 .406737 .913545 -15 298)"/></g><path fill="#ffedee" d="M0 0h350v350H0z"/><g fill="#fff"><path d="M20 20h310v310H20z"/><path d="M20 20h310v310H20z"/><use href="#B"/><use href="#B" y="324"/><use href="#C"/><use href="#C" x="315"/></g>';
    } else if (background == 3) {
      backgroundS = '<path fill="#fff" d="M0 0h350v350H0z"/><path d="M302.965 63.813c-.934-12.049-18.161-15.28-23.923-3.231-6.112-12.049-22.178-8.818-23.924 3.33-1.746 11.949 16.327 26.543 23.924 31.694 6.739-5.413 24.858-19.845 23.923-31.794z" stroke="#ffe3e3" stroke-width="5"/>';
    } else if (background == 4) {
      backgroundS = '<path fill="#fff" d="M0 0h350v350H0z"/><g stroke="#ffe8e8" stroke-width="14"><use xlink:href="#B" stroke-opacity=".5"/><use xlink:href="#B" x="254" y="193" stroke-opacity=".5"/></g><defs ><path id="B" d="M195 48.519c-2-74-104-92.5-137-23.5-33-69-135-50.5-137 23.5 0 81.481 104 151 137 175.5 33-24.5 137-98.5 137-175.5z"/></defs>';
    } else if (background == 5) {
      backgroundS = '<defs><path id="A" d="M54.343 13.193C53.946-1.484 33.716-5.153 27.171 8.532 20.627-5.153.397-1.484 0 13.193 0 29.353 20.627 43.141 27.171 48c6.545-4.859 27.171-19.536 27.171-34.807z" stroke="#ffedee" stroke-width="5"/></defs><g id="B"><use href="#A" transform="matrix(.913545 -.406737 .406737 .913545 62 3)"/><use href="#A" transform="matrix(.913545 .406737 -.406737 .913545 163 -18)"/><use href="#A" transform="matrix(.913545 -.406737 .406737 .913545 230 6)"/></g><g id="C"><use href="#A" transform="matrix(.913545 .406737 -.406737 .913545 -1 24)"/><use href="#A" transform="matrix(.913545 -.406737 .406737 .913545 -15 128)"/><use href="#A" transform="matrix(.913545 .406737 -.406737 .913545 -1 190)"/><use href="#A" transform="matrix(.913545 -.406737 .406737 .913545 -15 298)"/></g><path d="M0 0h350v350H0z"/><use href="#B"/><use href="#B" y="324"/><use href="#C"/><use href="#C" x="315"/>';
    }
    string memory textMargin;
    string memory textAnchor;
    if (textAlign == 0) {
      textAnchor = 'left';
      textMargin = toString(margin);
    } else if (textAlign == 1) {
      textAnchor = 'middle';
      textMargin = '50%';
    } else if (textAlign == 2) {
      textAnchor = 'right';
      textMargin = toString(margin);
    }
    // console.log('file: LoveNotes.sol ~ line start', note.length);
    string memory output = '';
    for (uint256 i = 0; i < note.length; i++) {
      // console.log('file: LoveNotes.sol ~ line 110 ~ )purereturns ~ i', i);
      string memory noteString = note[i];
      // console.log('file: LoveNotes.sol ~ line 110 ~ )purereturns ~ i2', i);
      uint256 y = marginTop + ((fontSize * 6) / 5) * i;
      // console.log('file: LoveNotes.sol ~ line 113 ~ )viewreturns ~ y', y);
      output = string(
        abi.encodePacked(
          output,
          '<tspan x="',
          textMargin,
          '" y="',
          toString(y),
          '" text-anchor="',
          textAnchor,
          '">',
          noteString,
          '</tspan>'
        )
      );
    }
    output = string(
      abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="350" height="350" fill="none">',
        backgroundS,
        '<text fill="#720000" font-family="Bodoni 72" font-size="',
        toString(fontSize),
        '" font-weight="bold" letter-spacing="0em">',
        output,
        '</text></svg>'
      )
    );
    return output;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    string memory output = preview(
      notes[tokenId].note,
      notes[tokenId].background,
      notes[tokenId].fontSize,
      notes[tokenId].margin,
      notes[tokenId].marginTop,
      notes[tokenId].textAlign
    );
    output = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Love Forever", "description": "Love notes stored on the blockchain forever", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(output)),
            '"}'
          )
        )
      )
    );
    return string(abi.encodePacked('data:application/json;base64,', output));
  }

  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
    if (value == 0) {
      return '0';
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
  bytes internal constant TABLE =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
    uint256 len = data.length;
    if (len == 0) return '';
    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((len + 2) / 3);
    // Add some extra buffer at the end
    bytes memory result = new bytes(encodedLen + 32);
    bytes memory table = TABLE;
    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)
      for {
        let i := 0
      } lt(i, len) {

      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)
        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)
        mstore(resultPtr, out)
        resultPtr := add(resultPtr, 4)
      }
      switch mod(len, 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }
      mstore(result, encodedLen)
    }
    return string(result);
  }
}
