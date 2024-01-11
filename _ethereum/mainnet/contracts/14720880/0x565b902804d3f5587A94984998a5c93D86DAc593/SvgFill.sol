//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SvgElement.sol";
import "./LogoHelper.sol";

library SvgFill {
  struct Fill {
    string id;
    string class;
    string fillType;
    string[] colors;
    bool animate;
  }

  // FILL //
  function getFillDefs(string memory seed, Fill memory fill) public pure returns (string memory) {
    string memory defs = '';
    if (LogoHelper.equal(fill.fillType, 'Linear Gradient') || LogoHelper.equal(fill.fillType, 'Blocked Linear Gradient')) {
      if (!fill.animate) {
        defs = SvgElement.getLinearGradient(SvgElement.LinearGradient(fill.id, fill.colors, LogoHelper.equal(fill.fillType, 'Blocked Linear Gradient'), ''));
      } else {
       string memory val = LogoHelper.toString(LogoHelper.randomInRange(seed, 100 , 0));
       string memory values = string(abi.encodePacked(val,
                                                      '%;',
                                                      LogoHelper.toString(LogoHelper.randomInRange(string(abi.encodePacked(seed, 'a')), 100 , 0)),
                                                      '%;',
                                                      val,
                                                      '%;'));
        val = LogoHelper.toString(LogoHelper.randomInRange(seed, 50000 , 5000));
        defs = SvgElement.getLinearGradient(SvgElement.LinearGradient(fill.id, fill.colors, LogoHelper.equal(fill.fillType, 'Blocked Linear Gradient'), SvgElement.getAnimate(SvgElement.Animate(getLinearAnimationType(seed), '', values, val, '0', getAnimationRepeat(seed), 'freeze'))));
      }
    } else if (LogoHelper.equal(fill.fillType, 'Radial Gradient') || LogoHelper.equal(fill.fillType, 'Blocked Radial Gradient')) {
      if (!fill.animate) {
        defs = SvgElement.getRadialGradient(SvgElement.RadialGradient(fill.id, fill.colors, LogoHelper.equal(fill.fillType, 'Blocked Radial Gradient'), ''));
      } else {
        string memory val = LogoHelper.toString(LogoHelper.randomInRange(seed, 100, 0));
        string memory values = string(abi.encodePacked(val,
                                                      '%;',
                                                      LogoHelper.toString(LogoHelper.randomInRange(string(abi.encodePacked(seed, 'a')), 100 , 0)),
                                                      '%;',
                                                      val,
                                                      '%;'));
        val = LogoHelper.toString(LogoHelper.randomInRange(seed, 10000 , 5000));
        defs = SvgElement.getRadialGradient(SvgElement.RadialGradient(fill.id, fill.colors, LogoHelper.equal(fill.fillType, 'Blocked Radial Gradient'), SvgElement.getAnimate(SvgElement.Animate(getRadialAnimationType(seed), '', values, val, '0', getAnimationRepeat(seed), 'freeze'))));
        
      }
    }
    return defs;
  }

  function getFillStyles(Fill memory fill) public pure returns (string memory) {
    if (LogoHelper.equal(fill.fillType, 'Solid')) {
      return string(abi.encodePacked('.', fill.class, ' { fill: ', fill.colors[0], ' } '));
    } else if (LogoHelper.equal(fill.fillType, 'Linear Gradient')
                || LogoHelper.equal(fill.fillType, 'Radial Gradient')
                  || LogoHelper.equal(fill.fillType, 'Blocked Linear Gradient')
                    || LogoHelper.equal(fill.fillType, 'Blocked Radial Gradient')) {
      return string(abi.encodePacked('.', fill.class, ' { fill: url(#', fill.id, ') } '));
    }
    string memory styles = '';
    return styles;
  }

  function getLinearAnimationType(string memory seed) private pure returns (string memory) {
    string[4] memory types = ['x1', 'x2', 'y1', 'y2'];
    return types[LogoHelper.random(seed) % types.length];
  }

  function getRadialAnimationType(string memory seed) private pure returns (string memory) {
    string[3] memory types = ['fx', 'fy', 'r'];
    return types[LogoHelper.random(seed) % types.length];
  }

  function getAnimationRepeat(string memory seed) private pure returns (string memory) {
    string[3] memory types = ['indefinite', '1', '2'];
    return types[LogoHelper.random(seed) % types.length];
  }



}
