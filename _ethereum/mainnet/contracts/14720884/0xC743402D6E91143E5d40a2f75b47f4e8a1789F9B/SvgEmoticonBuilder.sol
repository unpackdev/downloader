//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SvgEmoticon.sol";
import "./SvgText.sol";
import "./SvgFill.sol";
import "./SvgElement.sol";
import "./LogoHelper.sol";

library SvgEmoticonBuilder {

  struct Emoticon {
    string id;
    string class;
    string emoticonType;
    SvgText.Text text;
    string paletteName;
    SvgFill.Fill[] fills;
    bool animate;
  }

  function getSvgDefs(string memory seed, Emoticon memory emoticon) public pure returns (string memory) {
    string memory defs = '';

    for (uint i=0; i < emoticon.fills.length; i++) {
      defs = string(abi.encodePacked(defs, SvgFill.getFillDefs(seed, emoticon.fills[i])));
    }

    defs = string(abi.encodePacked(defs, SvgText.getSvgDefs(seed, emoticon.text)));
    return defs;
  }

  function getSvgStyles(Emoticon memory emoticon) public pure returns (string memory) {
    string memory styles = '';

    styles = string(abi.encodePacked(styles, SvgText.getSvgStyles(emoticon.text)));

    for (uint i=0; i < emoticon.fills.length; i++) {
      styles = string(abi.encodePacked(styles, SvgFill.getFillStyles(emoticon.fills[i])));
    }

    if (LogoHelper.equal(emoticon.emoticonType, 'The Flippening')) {
      styles = string(abi.encodePacked(styles, string(abi.encodePacked('.', emoticon.class, ' { font-size: 28px; font-family: Helvetica } '))));
    } else if (LogoHelper.equal(emoticon.emoticonType, 'Probably Nothing')) {
      styles = string(abi.encodePacked(styles, string(abi.encodePacked('.', emoticon.class, ' { font-size: 48px; font-family: Helvetica } '))));
    } else if (LogoHelper.equal(emoticon.emoticonType, 'Fren')) {
      styles = string(abi.encodePacked(styles, string(abi.encodePacked('.', emoticon.class, ' { font-size: 112px; font-family: Helvetica } '))));
    } 
    return styles;
  }

  function getSvgContent(Emoticon memory emoticon) public pure returns (string memory) {
    string memory content;
    if (LogoHelper.equal(emoticon.emoticonType, 'The Flippening')) {
      content = SvgEmoticon.getTheFlippeningContent(emoticon.text.animate, emoticon.class, emoticon.text.class, emoticon.text.val);
    } else if (LogoHelper.equal(emoticon.emoticonType, 'Probably Nothing')) {
      content = SvgEmoticon.getProbablyNothingContent(emoticon.animate, emoticon.class, emoticon.text.class, emoticon.text.val);
    } else if (LogoHelper.equal(emoticon.emoticonType, 'Fren')) {
      content = SvgEmoticon.getFrenContent(emoticon.animate, emoticon.class, emoticon.text.class, emoticon.text.val);
    }
    return content;
  }
}
