//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Color.sol";
import "./SvgFill.sol";
import "./LogoHelper.sol";
import "./SvgHeader.sol";
import "./SvgBackground.sol";

library SvgBackgroundBuilder {

  struct SvgDescriptor {
    string seed;
    string svgVal;
    SvgBackground.Background background;
  }

  function getSvg(SvgDescriptor memory svg) public pure returns (SvgDescriptor memory) { 
    svg.svgVal = getSvgOpen(svg.background.width, svg.background.height);
    svg.svgVal = string(abi.encodePacked(svg.svgVal, getSvgDefs(svg)));
    svg.svgVal = string(abi.encodePacked(svg.svgVal, getSvgStyles(svg)));
    svg.svgVal = string(abi.encodePacked(svg.svgVal, getSvgContent(svg)));
    svg.svgVal = string(abi.encodePacked(svg.svgVal, getSvgClose()));
    return svg;
  }

  function getSvgOpen(uint16 width, uint16 height) public pure returns (string memory) {
    return SvgHeader.getHeader(width, height);
  }

  function getSvgDefs(SvgDescriptor memory svg) public pure returns (string memory) {
    string memory defs = '<defs>';
    defs = string(abi.encodePacked(defs, SvgBackground.getSvgDefs(svg.seed, svg.background)));
    defs = string(abi.encodePacked(defs, '</defs>'));
    return defs;
  }

  function getSvgStyles(SvgDescriptor memory svg) public pure returns (string memory) {
    string memory styles = '';
    styles = string(abi.encodePacked(styles, SvgBackground.getSvgStyles(svg.background)));
    styles = string(abi.encodePacked('<style>', styles, '</style>'));
    return styles;
  }

  function getSvgContent(SvgDescriptor memory svg) public pure returns (string memory) {
    return SvgBackground.getSvgContent(svg.background);
  }

  function getSvgClose() public pure returns (string memory) {
    return '</svg>';
  }
}
