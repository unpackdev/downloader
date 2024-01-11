//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SvgElement.sol";
import "./LogoHelper.sol";

library SvgFilter {

  struct Filter {
    string id;
    string filterType;
    string scale;
    bool animate;
  }

  function getFilterDef(string memory seed, Filter memory filter) public pure returns (string memory) {
    string memory defs = '';
    string memory turbulance;
    string memory animateTurbulance;
    if (LogoHelper.equal(filter.scale, '50')) {
      turbulance = LogoHelper.getTurbulance(seed, 10000, 100000);
      if (filter.animate) {
        animateTurbulance = string(abi.encodePacked(turbulance, '; ', LogoHelper.getTurbulance(filter.id, 10000, 100000), '; ', turbulance, '; '));
      }
    }

    if (filter.animate) {
      string memory element = SvgElement.getAnimate(SvgElement.Animate('baseFrequency', '', animateTurbulance, LogoHelper.toString(LogoHelper.randomInRange(seed, 100000, 100)), '0', 'indefinite', ''));
      element = SvgElement.getTurbulance(SvgElement.Turbulance('fractalNoise', turbulance, '5', 'r1', element));
      element = string(abi.encodePacked(element, SvgElement.getDisplacementMap(SvgElement.DisplacementMap('SourceGraphic', 'r1', 'r2', filter.scale, 'R', 'G', ''))));
      defs = string(abi.encodePacked(defs, SvgElement.getFilter(SvgElement.Filter(filter.id, element))));
    } else {
      string memory element = SvgElement.getTurbulance(SvgElement.Turbulance('fractalNoise', turbulance, '5', 'r1', ''));
      element = string(abi.encodePacked(element, SvgElement.getDisplacementMap(SvgElement.DisplacementMap('SourceGraphic', 'r1', 'r2', filter.scale, 'R', 'G', ''))));
      defs = string(abi.encodePacked(defs, SvgElement.getFilter(SvgElement.Filter(filter.id, element))));
    }
    return defs;
  }

}
