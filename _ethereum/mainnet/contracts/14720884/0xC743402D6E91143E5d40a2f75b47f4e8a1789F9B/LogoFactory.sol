//	SPDX-License-Identifier: MIT
/// @notice Initializes data transfer objects so svg can be built
pragma solidity ^0.8.0;

import "./LogoType.sol";
import "./SvgEmoticonBuilder.sol";
import "./SvgBackground.sol";
import "./SvgText.sol";
import "./LogoHelper.sol";

library LogoFactory {
  function initBackground(uint256 tokenId, uint256 seed) public view returns (SvgBackground.Background memory) {
    Color.Palette memory palette = LogoType.getPalette(seed);
    return getBackground(tokenId, seed, palette);
  }

  function initEmoticon(uint256 tokenId, uint256 seed, string memory val, SvgText.Font memory font) public view returns (SvgEmoticonBuilder.Emoticon memory) {
    Color.Palette memory palette = LogoType.getPalette(seed);
    return getEmoticon(tokenId, seed, val, font, palette);
  }

  function initText(uint256 tokenId, uint256 seed, string memory val, SvgText.Font memory font) public view returns (SvgText.Text memory) {
    Color.Palette memory palette = LogoType.getPalette(seed);
    string memory textType = LogoType.getTextType(seed);
    return getText(tokenId, seed >> 1, val, textType, font, palette);
  }

  function getBackground(uint256 tokenId, uint256 seed, Color.Palette memory palette) public view returns (SvgBackground.Background memory) {
    string memory backgroundType = LogoType.getBackgroundType(seed);
    SvgFill.Fill[] memory fills;
    string memory class = '';
    if (LogoHelper.equal(backgroundType, 'None')) {
      //
    } else if (LogoHelper.equal(backgroundType,'Box')) {
      class = getIdOrClass(tokenId, 'box-background');
      string[] memory fillClasses = new string[](1);
      fillClasses[0] = getIdOrClass(tokenId, 'box-background');
      fills = getFills(seed, fillClasses, 1, palette.backgroundColors, LogoType.getFillTypeAlt(seed));
    } else if (LogoHelper.equal(backgroundType, 'Pattern A') 
                || LogoHelper.equal(backgroundType, 'Pattern B')) {
      class = getIdOrClass(tokenId, 'pattern-background');
      string[] memory fillClasses = new string[](1);
      fillClasses[0] = getIdOrClass(tokenId, 'pattern-background');
      fills = getFills(seed, fillClasses, 1, palette.backgroundColors, '');
    } else if (LogoHelper.equal(backgroundType, 'Pattern AX2') 
                || LogoHelper.equal(backgroundType, 'Pattern BX2') 
                  || LogoHelper.equal(backgroundType, 'Pattern AB')) {
      class = getIdOrClass(tokenId, 'pattern-background');
      string[] memory fillClasses = new string[](2);
      fillClasses[0] = getIdOrClass(tokenId, 'pattern-background-1');
      fillClasses[1] = getIdOrClass(tokenId, 'pattern-background-2');
      fills = getFills(seed, fillClasses, 2, palette.backgroundColors, '');
    } else if (LogoHelper.equal(backgroundType, 'GM')) {
      class = getIdOrClass(tokenId, 'pattern-background');
      string[] memory fillClasses = new string[](5);
      fillClasses[0] = getIdOrClass(tokenId, 'pattern-background-1-1');
      fillClasses[1] = getIdOrClass(tokenId, 'pattern-background-1-2');

      fillClasses[2] = getIdOrClass(tokenId, 'pattern-background-2-1');
      fillClasses[3] = getIdOrClass(tokenId, 'pattern-background-2-2');

      fillClasses[4] = getIdOrClass(tokenId, 'pattern-background-3');
      fills = getFills(seed, fillClasses, 5, palette.backgroundColors, '');
    }
    SvgFilter.Filter memory filter = getFilter(tokenId, seed >> 10);
    return SvgBackground.Background(getIdOrClass(tokenId, 'background'), class, backgroundType, palette.name, 0, 0, fills, filter);
  }

  function getEmoticon(uint256 tokenId, uint256 seed, string memory txtVal, SvgText.Font memory font, Color.Palette memory palette) public view returns (SvgEmoticonBuilder.Emoticon memory) {
    SvgFill.Fill[] memory fills;
    string memory class = getIdOrClass(tokenId, 'emoticon');
    string memory emoticonType = LogoType.getEmoticonType(seed);
    SvgText.Text memory text = getText(tokenId, seed, txtVal, emoticonType, font, palette);
    if (LogoHelper.equal(emoticonType, 'Text')) {
      fills = new SvgFill.Fill[](0);
    } else {
      string[] memory fillClasses = new string[](1);
      fillClasses[0] = getIdOrClass(tokenId, 'emoticon');
      fills = getFills(seed >> 1, fillClasses, 1, palette.emoticonColors, 'Solid');
    }
    return SvgEmoticonBuilder.Emoticon(getIdOrClass(tokenId, 'emoticon'), class, emoticonType, text, palette.name, fills, true);
  }

  function getText(uint256 tokenId, uint256 seed, string memory val, string memory textType, SvgText.Font memory font, Color.Palette memory palette) public pure returns (SvgText.Text memory) {
    SvgFill.Fill[] memory fills;
    string memory class;
    uint256 size;

    if (LogoHelper.equal(textType, 'Mailbox') 
          || LogoHelper.equal(textType, 'Warped Mailbox')) {
      uint256 iSize = 300 / (bytes(val).length - 1);
      iSize = iSize <= 80 ? iSize : 80;
      size = iSize;
      string[] memory fillClasses = new string[](4);
      fillClasses[0] = getIdOrClass(tokenId, 'text-1');
      fillClasses[1] = getIdOrClass(tokenId, 'text-2');
      fillClasses[2] = getIdOrClass(tokenId, 'text-3');
      fillClasses[3] = getIdOrClass(tokenId, 'text-4');
      fills = getFills(seed, fillClasses, 4, palette.textColors, 'Solid');
      class = getIdOrClass(tokenId, 'text');
    } else if (LogoHelper.equal(textType, 'The Flippening')
                  || LogoHelper.equal(textType, 'Probably Nothing')) {
      uint256 iSize = 150 / (bytes(val).length - 1);
      iSize = iSize <= 12 ? iSize : 12;
      size = iSize;
      string[] memory fillClasses = new string[](1);
      fillClasses[0] = getIdOrClass(tokenId, 'emoticon-text');
      fills = getFills(seed, fillClasses, 1, palette.textColors, 'Solid');
      class = getIdOrClass(tokenId, 'emoticon-text');
    } else if (LogoHelper.equal(textType, 'Rug Pull')) {
      uint256 iSize = 300 / (bytes(val).length - 1);
      iSize = iSize <= 80 ? iSize : 80;
      size = iSize;
      string[] memory fillClasses = new string[](1);
      fillClasses[0] = getIdOrClass(tokenId, 'text');
      fills = getFills(seed, fillClasses, 1, palette.textColors, 'Solid');
      class = getIdOrClass(tokenId, 'text');
    } else if (LogoHelper.equal(textType, 'Fren')) {
      uint256 iSize = 150 / (bytes(val).length - 1);
      iSize = iSize <= 12 ? iSize : 12;
      size = iSize;
      string[] memory fillClasses = new string[](1);
      fillClasses[0] = getIdOrClass(tokenId, 'emoticon-text');
      fills = getFills(seed, fillClasses, 1, palette.textColors, 'Solid');
      class = getIdOrClass(tokenId, 'emoticon-text');
    } else if (LogoHelper.equal(textType, 'NGMI')) {
      uint256 iSize = 300 / (bytes(val).length - 1);
      iSize = iSize <= 80 ? iSize : 80;
      size = iSize;
      string[] memory fillClasses = new string[](1);
      fillClasses[0] = getIdOrClass(tokenId, 'text');
      fills = getFills(seed, fillClasses, 1, palette.textColors, 'Solid');
      class = getIdOrClass(tokenId, 'text');
    } else if (LogoHelper.equal(textType, 'Plain')) {
      uint256 iSize = 300 / (bytes(val).length - 1);
      iSize = iSize <= 80 ? iSize : 80;
      size = iSize;
      string[] memory fillClasses = new string[](1);
      fillClasses[0] = getIdOrClass(tokenId, 'text');
      fills = getFills(seed, fillClasses, 1, palette.textColors, 'Solid');
      class = getIdOrClass(tokenId, 'text');
    }
    return SvgText.Text(class, class, val, textType, font, size, palette.name, fills, LogoType.getAnimationType(seed));
  }

  function getFills(uint256 seed, string[] memory classes, uint num, string[] memory palette, string memory fillTypeOverride) public pure returns (SvgFill.Fill[] memory) {
    SvgFill.Fill[] memory fills = new SvgFill.Fill[](num);
    for (uint i=0; i < num; i++) {
      string memory fillType = LogoHelper.equal(fillTypeOverride, '') ? LogoType.getFillType(seed >> i) : fillTypeOverride;
      string[] memory colors;
      if (LogoHelper.equal(fillType, 'Solid')) {
        colors = new string[](1);
        colors[0] = LogoType.getFillColor(seed >> i * 8, palette);
      } else if (LogoHelper.equal(fillType, 'Linear Gradient')
                  || LogoHelper.equal(fillType, 'Radial Gradient')
                      || LogoHelper.equal(fillType, 'Blocked Linear Gradient')
                        || LogoHelper.equal(fillType, 'Blocked Radial Gradient')) {
        colors = new string[](5);
        colors[0] = LogoType.getFillColor(seed >> (i * 5) + 1, palette);
        colors[1] = LogoType.getFillColor(seed >> (i * 5) + 2, palette);
        colors[2] = LogoType.getFillColor(seed >> (i * 5) + 3, palette);
        colors[3] = LogoType.getFillColor(seed >> (i * 5) + 4, palette);
        colors[4] = LogoType.getFillColor(seed >> (i * 5) + 5, palette);
      }
      string memory fillId = string(abi.encodePacked(classes[i], '-fill'));
      fills[i] = SvgFill.Fill(fillId, classes[i], fillType, colors, LogoType.getAnimationType(seed >> (i * 5) + 6));
    }
    return fills;
  }

  function getFilter(uint256 tokenId, uint256 seed) public pure returns (SvgFilter.Filter memory) {
    string memory filterType = LogoType.getFilterType(seed);
    bool animate = LogoType.getAnimationType(seed >> 1);
    return SvgFilter.Filter(getIdOrClass(tokenId, 'filter'), filterType, '50', animate);
  }

  function getIdOrClass(uint256 tokenId, string memory name) public pure returns (string memory) {
    return string(abi.encodePacked('tid', LogoHelper.toString(tokenId), '-', name));
  }
}