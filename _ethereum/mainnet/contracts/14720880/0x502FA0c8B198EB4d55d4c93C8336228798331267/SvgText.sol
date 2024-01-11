//	SPDX-License-Identifier: MIT
/// @title  Text Logo Elements
/// @notice On-chain SVG
pragma solidity ^0.8.0;

import "./SvgFill.sol";
import "./SvgElement.sol";
import "./LogoHelper.sol";

library SvgText {

  struct Font {
    string link;
    string name;
  }
  
  struct Text {
    string id;
    string class;
    string val;
    string textType;
    Font font;
    uint256 size;
    string paletteName;
    SvgFill.Fill[] fills;
    bool animate;
  }

  function getSvgDefs(string memory seed, Text memory text) public pure returns (string memory) {
    string memory defs = '';

    for (uint i = 0; i < text.fills.length; i++) {
      defs = string(abi.encodePacked(defs, SvgFill.getFillDefs(seed, text.fills[i])));
    }

    if (LogoHelper.equal(text.textType, 'Rug Pull')) {
      uint256[] memory ys = getRugPullY(text);
      for (uint8 i = 0; i < 4; i++) {
        string memory path = SvgElement.getRect(SvgElement.Rect('', '', LogoHelper.toString(ys[i] + 3), '100%', '100%', '', '', ''));
        string memory id = string(abi.encodePacked('clip-', LogoHelper.toString(i)));
        defs = string(abi.encodePacked(defs, SvgElement.getClipPath(SvgElement.ClipPath(id, path))));
      }
    }
    return defs;
  }
  
  // TEXT //
  function getSvgStyles(Text memory text) public pure returns (string memory) {
    string memory styles = !LogoHelper.equal(text.font.link, '') ? string(abi.encodePacked('@import url(', text.font.link, '); ')) : '';
    styles = string(abi.encodePacked(styles, '.', text.class, ' { font-family:', text.font.name, '; font-size: ', LogoHelper.toString(text.size), 'px; font-weight: 800; } '));

    for (uint i=0; i < text.fills.length; i++) {
      styles = string(abi.encodePacked(styles, SvgFill.getFillStyles(text.fills[i])));
    }
    return styles;
  }

  function getSvgContent(Text memory text) public pure returns (string memory) {
    string memory content = '';
    if (LogoHelper.equal(text.textType, 'Plain')) {
      content = SvgElement.getText(SvgElement.Text(text.class, '50%', '50%', '', '', '', 'central', 'middle', '', '', '', text.val));
    } else if (LogoHelper.equal(text.textType, 'Rug Pull')) {
      content = getRugPullContent(text);
    } else if (LogoHelper.equal(text.textType, 'Mailbox') || LogoHelper.equal(text.textType, 'Warped Mailbox')) {
      uint8 iterations = LogoHelper.equal(text.textType, 'Mailbox') ? 2 : 30;
      for (uint8 i = 0; i < iterations; i++) {
        content = string(abi.encodePacked(content, SvgElement.getText(SvgElement.Text(string(abi.encodePacked(text.class, ' ', text.fills[i % text.fills.length].class)), '50%', '50%', LogoHelper.toString(iterations - i), LogoHelper.toString(iterations - i), '', 'central', 'middle', '', '', '', text.val))));
      }
      content = string(abi.encodePacked(content, SvgElement.getText(SvgElement.Text(string(abi.encodePacked(text.class, ' ', text.fills[text.fills.length - 1].class)), '50%', '50%', '', '', '', 'central', 'middle', '', '', '', text.val))));
    } else if (LogoHelper.equal(text.textType, 'NGMI')) {
      string memory rotate = LogoHelper.getRotate(text.val);
      content = SvgElement.getText(SvgElement.Text(text.class, '50%', '50%', '', '', '', 'central', 'middle', rotate, '', '', text.val));
    }
    return content;
  }

  function getRugPullContent(Text memory text) public pure returns (string memory) {
    // get first animation y via y_prev = (y of txt 1) - font size / 2)
    // next animation goes to y_prev + (font size / 3)
    // clip path is txt elemnt y + 3

    string memory content = '';
    uint256[] memory ys = getRugPullY(text);

    string memory element = SvgElement.getAnimate(SvgElement.Animate('y', LogoHelper.toString(ys[4]), '', '2600', '0', '1', 'freeze'));
    element = string(abi.encodePacked(text.val, element));
    element = SvgElement.getText(SvgElement.Text(text.class, '50%', LogoHelper.toString(ys[0]), '', '', '', 'alphabetic', 'middle', '', '', 'clip-3', element));      

    content = element;
    element = SvgElement.getAnimate(SvgElement.Animate('y', LogoHelper.toString(ys[3]), '', '2400', '0', '1', 'freeze'));
    element = string(abi.encodePacked(text.val, element));
    element = SvgElement.getText(SvgElement.Text(text.class, '50%', LogoHelper.toString(ys[0]), '', '', '', 'alphabetic', 'middle', '', '', 'clip-2', element));    
    content = string(abi.encodePacked(content, element));

    element = SvgElement.getAnimate(SvgElement.Animate('y', LogoHelper.toString(ys[2]), '', '2200', '0', '1', 'freeze'));
    element = string(abi.encodePacked(text.val, element));
    element = SvgElement.getText(SvgElement.Text(text.class, '50%', LogoHelper.toString(ys[0]), '', '', '', 'alphabetic', 'middle', '', '', 'clip-1', element));      
    content = string(abi.encodePacked(content, element));

    element = SvgElement.getAnimate(SvgElement.Animate('y', LogoHelper.toString(ys[1]), '', '2000', '0', '1', 'freeze'));
    element = string(abi.encodePacked(text.val, element));
    element = SvgElement.getText(SvgElement.Text(text.class, '50%', LogoHelper.toString(ys[0]), '', '', '', 'alphabetic', 'middle', '', '', 'clip-0', element));
    content = string(abi.encodePacked(content, element));

    return string(abi.encodePacked(content, SvgElement.getText(SvgElement.Text(text.class, '50%', LogoHelper.toString(ys[0]), '', '', '', 'alphabetic', 'middle', '', '', '', text.val))));
  }

  function getRugPullY(Text memory text) public pure returns (uint256[] memory) {
    uint256[] memory ys = new uint256[](5);
    uint256 y =  (text.size - (text.size / 4)) + (text.size / 2) + (text.size / 3) + (text.size / 4) + (text.size / 5);
    y = ((300 - y) / 2) + (text.size - (text.size / 4));
    ys[0] = y;
    y = y + text.size / 2;
    ys[1] = y;
    y = y + text.size / 3;
    ys[2] = y;
    y = y + text.size / 4;
    ys[3] = y;
    y = y + text.size / 5;
    ys[4] = y;
    return ys;
  }
}
