//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SvgFill.sol";
import "./SvgFilter.sol";
import "./SvgElement.sol";
import "./LogoHelper.sol";
import "./SvgPattern.sol";

library SvgBackground {

  struct Background {
    string id;
    string class;
    string backgroundType;
    string paletteName;
    uint16 width;
    uint16 height;
    SvgFill.Fill[] fills;
    SvgFilter.Filter filter;
  }

  function getSvgDefs(string memory seed, Background memory background) public pure returns (string memory) {
    string memory defs = '';
    // Fill defs
    for (uint i=0; i < background.fills.length; i++) {
      defs = string(abi.encodePacked(defs, SvgFill.getFillDefs(seed, background.fills[i])));
    }

    // Filter defs
    if (LogoHelper.equal(background.filter.filterType, 'A')) {
      defs = string(abi.encodePacked(defs, SvgFilter.getFilterDef(string(abi.encodePacked(seed, 'a')), background.filter)));
      if (LogoHelper.equal(background.backgroundType, 'GM')) {
        string memory originalId = background.filter.id;
        background.filter.id = string(abi.encodePacked(background.filter.id, '-2'));
        defs = string(abi.encodePacked(defs, SvgFilter.getFilterDef(string(abi.encodePacked(seed, 'b')), background.filter)));
        background.filter.id = originalId;
      }
    }

    // Pattern defs
    if (LogoHelper.equal(background.backgroundType, 'Pattern A')) { 
      defs = string(abi.encodePacked(defs, SvgPattern.getADef(seed, background.id, background.fills[0].fillType, background.fills[0].class)));
    } else if (LogoHelper.equal(background.backgroundType, 'Pattern B')) { 
      defs = string(abi.encodePacked(defs, SvgPattern.getBDef(seed, background.id, background.fills[0].class)));
    } else if (LogoHelper.equal(background.backgroundType, 'Pattern AX2')) { 
      defs = string(abi.encodePacked(defs, SvgPattern.getAX2Def(seed, background.id, background.fills[0].class, background.fills[0].fillType, background.fills[1].class)));
    } else if (LogoHelper.equal(background.backgroundType, 'Pattern BX2')) { 
      defs = string(abi.encodePacked(defs, SvgPattern.getBX2Def(seed, background.id, background.fills[0].class, background.fills[1].class)));
    } else if (LogoHelper.equal(background.backgroundType, 'Pattern AB')) { 
      defs = string(abi.encodePacked(defs, SvgPattern.getABDef(seed, background.id, background.fills[0].fillType, background.fills[0].class, background.fills[1].class)));
    } else if (LogoHelper.equal(background.backgroundType, 'GM')) { 
      defs = string(abi.encodePacked(defs, SvgPattern.getGMDef(seed, background.id, background.fills[0].class, background.fills[1].class, background.fills[2].class, background.fills[3].class)));
    }
    return defs;
  }

  function getSvgStyles(Background memory background) public pure returns (string memory) {
    string memory styles = '';
    for (uint i=0; i < background.fills.length; i++) {
      styles = string(abi.encodePacked(styles, SvgFill.getFillStyles(background.fills[i])));
    }
    return styles;
  }

  function getSvgContent(Background memory background) public pure returns (string memory) {
    if (LogoHelper.equal(background.backgroundType, 'Box')) {
      return SvgElement.getRect(SvgElement.Rect(background.class, '0', '0', '100%', '100%', '', '', ''));
    } else if (LogoHelper.equal(background.backgroundType, 'Pattern A')
                || LogoHelper.equal(background.backgroundType, 'Pattern AX2')
                  || LogoHelper.equal(background.backgroundType, 'Pattern B')
                    || LogoHelper.equal(background.backgroundType, 'Pattern BX2')
                      || LogoHelper.equal(background.backgroundType, 'Pattern AB')) {
      if (LogoHelper.equal(background.filter.filterType, 'None')) {
        return SvgElement.getRect(SvgElement.Rect('', '0', '0', '100%', '100%', '', background.id, ''));
      } else {
        return SvgElement.getRect(SvgElement.Rect('', '0', '0', '100%', '100%', '', background.id, background.filter.id));
      }
    } else if (LogoHelper.equal(background.backgroundType, 'GM')) {
      string memory backgroundId1 = string(abi.encodePacked(background.id, '-1'));
      string memory backgroundId2 = string(abi.encodePacked(background.id, '-2'));
      string memory content = '';
      if (LogoHelper.equal(background.filter.filterType, 'None')) {
        content = SvgElement.getRect(SvgElement.Rect('', '0', '0', '100%', '70%', '0.8', backgroundId1, ''));
        content = string(abi.encodePacked(content, SvgElement.getCircle(SvgElement.Circle(background.fills[4].class, '80%', '50%', '15%', ''))));
        content = string(abi.encodePacked(content, SvgElement.getRect(SvgElement.Rect('', '0', '60%', '100%', '70%', '', backgroundId2, ''))));
        return content;
      } else {
        content = SvgElement.getRect(SvgElement.Rect('', '0', '0', '100%', '100%', '0.8', backgroundId1, background.filter.id));
        content = string(abi.encodePacked(content, SvgElement.getCircle(SvgElement.Circle(background.fills[4].class, '80%', '50%', '15%', ''))));
        content = string(abi.encodePacked(content, SvgElement.getRect(SvgElement.Rect('', '0', '60%', '100%', '70%', '', backgroundId2, string(abi.encodePacked(background.filter.id, '-2'))))));
        return content;
      }
    }
  }
}
