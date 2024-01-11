//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SvgElement.sol";

library SvgEmoticon {
  function getTheFlippeningContent(bool animate, string memory emoticonClass, string memory textClass, string memory text) public pure returns (string memory) {
    string memory animate = SvgElement.getAnimate(SvgElement.Animate('rotate', '', '0;20;0', '500', '0', '1', 'freeze'));
    string memory element = string(abi.encodePacked('\xE2\x95\xAF', animate, ''));

    string memory content = SvgElement.getTspan(SvgElement.Tspan(emoticonClass, '', '', '', element));

    content = string(abi.encodePacked(content, '\xC2\xB0\xE2\x96\xA1\xC2\xB0\xEF\xBC\x89', ''));
    element = string(abi.encodePacked('\xE2\x95\xAF', animate));

    content = string(abi.encodePacked(content, SvgElement.getTspan(SvgElement.Tspan(emoticonClass, '', '', '', element)), ''));

    element = string(abi.encodePacked('(', content, ''));

    content = SvgElement.getText(SvgElement.Text(emoticonClass, '20', '50%', '', '', '', 'central', 'start', '', '', '', element));
    
    animate = '<animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 160 110" to="180 220 150" begin="250ms" dur="500ms" repeatCount="1" fill="freeze"/>';
    element = SvgElement.getTspan(SvgElement.Tspan(textClass, '', '', '', text));
    element = string(abi.encodePacked(element, 'T', animate));
    element = string(abi.encodePacked('T', element));

    element = SvgElement.getText(SvgElement.Text(emoticonClass, '160', '140', '', '', '', 'hanging', 'start', '', '', '', element));
    return string(abi.encodePacked(content, element)); 
  }

  function getProbablyNothingContent(bool animate, string memory emoticonClass, string memory textClass, string memory text) public pure returns (string memory) {
    string memory element = SvgElement.getTspan(SvgElement.Tspan(textClass, '', '2', '-18', text));
    element = string(abi.encodePacked('\xC2\xAF\x5C\x5F\x28\xE3\x83\x84\x29\x5F\x2F', element));
    element = string(abi.encodePacked(element, '<animate attributeName="dy" values="0;-2,0,0,2,0,0,-2;0;-2,0,0,2,0,0,-2;0" dur="2s" repeatCount="1"/>'));
    return SvgElement.getText(SvgElement.Text(emoticonClass, '10%', '50%', '', '', '', 'central', 'start', '', '', '', element));
  }

  function getFrenContent(bool animate, string memory emoticonClass, string memory textClass, string memory text) public pure returns (string memory) {
    string memory element = SvgElement.getTspan(SvgElement.Tspan(textClass, '', '1', '', text));
    element = string(abi.encodePacked('(^', element, '^)'));

    bytes memory byteString = bytes(text);
    string memory dy = '0,-2,2,';
    for (uint i = 1; i < byteString.length; i++) {
      dy = string(abi.encodePacked(dy, '0,'));
    }
    dy = string(abi.encodePacked('0;', dy, '-2,2;', '0;'));
    element = string(abi.encodePacked(element, SvgElement.getAnimate(SvgElement.Animate('dy', '', dy, '1500', '500', '1', ''))));
    return SvgElement.getText(SvgElement.Text(emoticonClass, '50%', '50%', '', '', '', 'central', 'middle', '', '', '', element));
  }
}