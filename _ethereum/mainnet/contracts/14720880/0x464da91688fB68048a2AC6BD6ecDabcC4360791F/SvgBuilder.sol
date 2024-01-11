//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Color.sol";
import "./SvgFill.sol";
import "./LogoHelper.sol";
import "./SvgText.sol";

library SvgTextBuilder {

  struct SvgDescriptor {
    string seed;
    string svgVal;
    SvgText.Text text;
  }

  function getSvg(SvgDescriptor memory svg) public pure returns (SvgDescriptor memory) { 
    svg.svgVal = getSvgOpen();
    svg.svgVal = string(abi.encodePacked(svg.svgVal, getSvgDefs(svg)));
    svg.svgVal = string(abi.encodePacked(svg.svgVal, getSvgStyles(svg)));
    svg.svgVal = string(abi.encodePacked(svg.svgVal, getSvgContent(svg)));
    svg.svgVal = string(abi.encodePacked(svg.svgVal, getSvgClose()));
    return svg;
  }

  function getSvgOpen() public pure returns (string memory) {
    return '<svg version="2.0" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 300 300">';
  }

  function getSvgDefs(SvgDescriptor memory svg) public pure returns (string memory) {
    string memory defs = '<defs>';
    defs = string(abi.encodePacked(defs, SvgText.getSvgDefs(svg.seed, svg.text)));
    defs = string(abi.encodePacked(defs, '</defs>'));
    return defs;
  }

  function getSvgStyles(SvgDescriptor memory svg) public pure returns (string memory) {
    string memory styles = '';
    styles = string(abi.encodePacked(styles, SvgText.getSvgStyles(svg.text)));
    styles = string(abi.encodePacked('<style>', styles, '</style>'));
    return styles;
  }

  function getSvgContent(SvgDescriptor memory svg) public pure returns (string memory) {
    return SvgText.getSvgContent(svg.text);
  }

  function getSvgClose() public pure returns (string memory) {
    return '</svg>';
  }
}
