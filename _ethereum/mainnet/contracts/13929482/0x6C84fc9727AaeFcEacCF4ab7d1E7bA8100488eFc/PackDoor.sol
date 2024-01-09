// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Base64.sol";
import "./Strings.sol";
/// @title PackDoor
/// @notice Provides a function for concatenating a base64 encoded SVG object
/// @author druzy

library PackDoor {
    using Strings for uint256;
    function buildDoor(uint currentToken) external pure returns (string memory json) {
    string[59] memory doorMetaData = [
      "I","II","II","II","II","III","III","III","III","III","III","III","III","IV","IV","IV","IV","IV","IV","IV","IV","IV","IV","IV","IV","IV","IV","IV","IV","IV","IV","IV","IV",
      "FIRE", "EARTH", "METAL", "WATER", "WOOD", "MOUNTAIN", "WIND", "HEAVEN", "THUNDER", "SUN", "MOON", "STAR", "SOUL", "SPACE", "TIME", "VOID",
      "SWORD", "WAND", "TOKEN", "CHARM",
      "fff","fff","fff",
      "FIRE", "EARTH", "METAL"
    ];

    if (uint256(keccak256(abi.encodePacked("ELEMENT", currentToken))) % 16 == 0) {
      doorMetaData[53] = "FF665C";
      doorMetaData[54] = "FCCE87";
      doorMetaData[55] = "D4FF97";
    } else if (uint256(keccak256(abi.encodePacked("ELEMENT", currentToken))) % 16 == 1) {
      doorMetaData[53] = "46C485";
      doorMetaData[54] = "DDC003";
      doorMetaData[55] = "D4FF97";
    } else if (uint256(keccak256(abi.encodePacked("ELEMENT", currentToken))) % 16 == 2) {
      doorMetaData[53] = "6B6C94";
      doorMetaData[54] = "FFFFFF";
      doorMetaData[55] = "E6D6E5";
    } else if (uint256(keccak256(abi.encodePacked("ELEMENT", currentToken))) % 16 == 3) {
      doorMetaData[53] = "3050EE";
      doorMetaData[54] = "093DEA";
      doorMetaData[55] = "1EB79E";
    } else if (uint256(keccak256(abi.encodePacked("ELEMENT", currentToken))) % 16 == 4) {
      doorMetaData[53] = "3B302C";
      doorMetaData[54] = "FCCE87";
      doorMetaData[55] = "E7E2E2";
    } else if (uint256(keccak256(abi.encodePacked("ELEMENT", currentToken))) % 16 == 5) {
      doorMetaData[53] = "F63F23";
      doorMetaData[54] = "652FC4";
      doorMetaData[55] = "FFD037";
    } else if (uint256(keccak256(abi.encodePacked("ELEMENT", currentToken))) % 16 == 6) {
      doorMetaData[53] = "E2E0EA";
      doorMetaData[54] = "CFF6CC";
      doorMetaData[55] = "FFFFFF";
    } else if (uint256(keccak256(abi.encodePacked("ELEMENT", currentToken))) % 16 == 7) {
      doorMetaData[53] = "EA9EFE";
      doorMetaData[54] = "FCCE87";
      doorMetaData[55] = "CAFFC4";
    } else if (uint256(keccak256(abi.encodePacked("ELEMENT", currentToken))) % 16 == 8) {
      doorMetaData[53] = "E7DAF0";
      doorMetaData[54] = "EF5A82";
      doorMetaData[55] = "F9F95B";
    } else if (uint256(keccak256(abi.encodePacked("ELEMENT", currentToken))) % 16 == 9) {
      doorMetaData[53] = "F2C40C";
      doorMetaData[54] = "FF665C";
      doorMetaData[55] = "EBFD85";
    } else if (uint256(keccak256(abi.encodePacked("ELEMENT", currentToken))) % 16 == 10) {
      doorMetaData[53] = "325B5F";
      doorMetaData[54] = "FFFFFF";
      doorMetaData[55] = "FFFFFF";
    } else if (uint256(keccak256(abi.encodePacked("ELEMENT", currentToken))) % 16 == 11) {
      doorMetaData[53] = "F2FF62";
      doorMetaData[54] = "EF6FC0";
      doorMetaData[55] = "C7C3DF";
    } else if (uint256(keccak256(abi.encodePacked("ELEMENT", currentToken))) % 16 == 12) {
      doorMetaData[53] = "5614FC";
      doorMetaData[54] = "5614FC";
      doorMetaData[55] = "5614FC";
    } else if (uint256(keccak256(abi.encodePacked("ELEMENT", currentToken))) % 16 == 13) {
      doorMetaData[53] = "2E2D3A";
      doorMetaData[54] = "2E2D3A";
      doorMetaData[55] = "2E2D3A";
    } else if (uint256(keccak256(abi.encodePacked("ELEMENT", currentToken))) % 16 == 14) {
      doorMetaData[53] = "FFFFFF";
      doorMetaData[54] = "FFFFFF";
      doorMetaData[55] = "FFFFFF";
    } else {
      doorMetaData[53] = "000000";
      doorMetaData[54] = "000000";
      doorMetaData[55] = "000000";
    }

    string memory svgDoor;
    string[2] memory currentRing;
    

  if (uint256(keccak256(abi.encodePacked("RING", currentToken))) % 33 == 0) {
   currentRing = ["ring-1", "9"];
   svgDoor = string(abi.encodePacked("<path class='shadow-rear' d='M166.64,145.79l-.13.23.24.14c2.61,1.65,2.14,6.28,2.14,6.33l.14,79.78-74.3-10.45L94.58,142s-.48-4.81,2.12-5.72l.24-.09-.13-.25a84.13,84.13,0,0,1-7.29-20.22c-3-13.81-1.32-25.22,4.93-33.89s15.34-13.06,21.82-15.17a98.48,98.48,0,0,0,11-4.66,47.09,47.09,0,0,1,4.36-2c1,.67,2.58,1.84,4.36,3.19,3.08,2.34,6.94,5.27,11,7.75,6.5,3.94,15.57,10.83,21.88,21.31s8,22.31,5.06,35.29A63.16,63.16,0,0,1,166.64,145.79Z'><animate attributeName='opacity' values='0.15;0.75;0.15' dur='2.3s' repeatCount='indefinite'/></path><path class='op-light shadow-mid' d='M158.24,154.2l-.14.22.24.15c2.61,1.64,2.14,6.28,2.14,6.33l.15,79.77L86.32,230.23l-.14-79.78s-.48-4.82,2.11-5.73l.24-.08-.13-.25a84.72,84.72,0,0,1-7.29-20.23c-3-13.8-1.32-25.21,4.94-33.88s15.33-13.06,21.81-15.18a95,95,0,0,0,11-4.66c1.76-.86,3.31-1.59,4.35-2,1,.68,2.59,1.84,4.36,3.2,3.09,2.34,6.94,5.27,11,7.74,6.49,3.94,15.56,10.83,21.88,21.32s8,22.31,5.05,35.29A63.08,63.08,0,0,1,158.24,154.2Z'><animate attributeName='opacity' values='0.15;0.75;0.15' dur='1.5s' repeatCount='indefinite'/></path><path class='shadow-front op-light' d='M149.83,162.6l-.13.23.24.14c2.61,1.65,2.14,6.28,2.14,6.33l.14,79.78-74.3-10.45-.15-79.78s-.48-4.81,2.12-5.72l.24-.09-.14-.25a84.72,84.72,0,0,1-7.28-20.22c-3-13.81-1.32-25.22,4.93-33.89S93,85.62,99.46,83.51a97.42,97.42,0,0,0,11-4.66,47.09,47.09,0,0,1,4.36-2c1,.67,2.58,1.84,4.36,3.19,3.08,2.34,6.94,5.27,11,7.75,6.5,3.94,15.56,10.83,21.88,21.31s8,22.31,5.06,35.29A63.16,63.16,0,0,1,149.83,162.6Z'><animate attributeName='opacity' values='0.15;0.75;0.15' dur='2s' repeatCount='indefinite'/></path><path class='door-stroke fg-color no-fill' d='M130.43,270.7,56.12,260.26,56,180.48s-.49-4.82,2.11-5.73l.24-.08-.14-.26a84.72,84.72,0,0,1-7.28-20.22c-3-13.81-1.32-25.21,4.94-33.88s15.32-13.06,21.81-15.18a94.79,94.79,0,0,0,11-4.67c1.77-.85,3.31-1.58,4.36-2,1,.67,2.58,1.84,4.36,3.19,3.09,2.35,6.94,5.27,11,7.74,6.5,3.95,15.57,10.85,21.89,21.33s8,22.3,5.05,35.28a63.25,63.25,0,0,1-7.2,18.18l-.14.23.24.14c2.6,1.65,2.14,6.29,2.14,6.33l.15,79.78M106.28,84.64l-.09,0c-1.07.37-2.58,1.1-4.49,2a97.45,97.45,0,0,1-10.91,4.65c-6.54,2.13-15.66,6.52-22,15.31s-8,20.32-5,34.28A85.38,85.38,0,0,0,71,161.05c-2.6,1.17-2.19,5.74-2.16,6.09L69,247.37,144.2,258l-.15-80.25c0-.17.48-4.75-2.17-6.69a64.35,64.35,0,0,0,7.13-18.1c3-13.12,1.23-25.14-5.14-35.71s-15.52-17.53-22.06-21.5A133.66,133.66,0,0,1,110.87,88c-1.92-1.45-3.43-2.6-4.5-3.27Zm21.62,99.81,14-13.44m-83.55,3.66L71,161.05M61.4,114.22,75.06,99.89M130.43,270.7,144.2,258m-88.08,2.31L69,247.37M106.37,84.7,93,98.5'/>"));
   } else if (uint256(keccak256(abi.encodePacked("RING", currentToken))) % 33 > 0 &&   uint256(keccak256(abi.encodePacked("RING", currentToken))) % 33 < 5) {
     currentRing = ["ring-2", "16"];
     svgDoor = "<path class='shadow-rear' d='M171.22,233.68l-75-10.55L96,127.92c0-.4,1.06-9.73,8.6-11.5l.35-.08-.22-.36a45.15,45.15,0,0,1-7-23.76c0-21.24,15.94-36.25,35.6-33.49S169.1,81,169.14,102.25a35.87,35.87,0,0,1-6.88,21.81l-.22.3.36.18c7.67,4,8.63,13.83,8.65,13.93Z'><animate attributeName='opacity' values='0.15;0.75;0.15' dur='2.3s' repeatCount='indefinite'/></path><path class='shadow-mid op-light' d='M162.6,242.3l-75-10.54-.19-95.22c0-.39,1.06-9.73,8.6-11.49l.36-.09-.22-.36a45,45,0,0,1-7-23.76c0-21.23,15.94-36.25,35.6-33.49s35.71,22.28,35.74,43.52a35.8,35.8,0,0,1-6.87,21.81l-.22.3.36.18c7.67,4,8.63,13.84,8.64,13.94Z'><animate attributeName='opacity' values='0.15;0.75;0.15' dur='1.5s' repeatCount='indefinite'/></path><path class='shadow-front op-light' d='M154,250.92,79,240.38l-.19-95.22c0-.39,1.06-9.73,8.6-11.49l.36-.09-.22-.35a45.07,45.07,0,0,1-7-23.77c0-21.23,15.94-36.25,35.59-33.49s35.71,22.28,35.75,43.52A35.87,35.87,0,0,1,145,141.31l-.22.29.35.19c7.68,4,8.64,13.83,8.65,13.93Z'><animate attributeName='opacity' values='0.15;0.75;0.15' dur='2s' repeatCount='indefinite'/></path><path class='door-stroke fg-color no-fill' d='M130.28,274.6l-75-10.54-.17-95.22c0-.39,1-9.73,8.59-11.49l.35-.09-.22-.35a45.28,45.28,0,0,1-7-23.77c0-21.22,15.94-36.25,35.61-33.48s35.7,22.28,35.74,43.51A35.83,35.83,0,0,1,121.32,165l-.22.3.36.18c7.68,3.95,8.63,13.83,8.64,13.93l.18,95.2M107.47,84.05c-20-2.81-36.18,12.44-36.14,34a45.73,45.73,0,0,0,6.85,23.78c-7.69,2.08-8.61,11.77-8.62,11.87v0l.18,95.83,76.11,10.69-.18-95.82c0-.13-1-10.09-8.67-14.33a36.54,36.54,0,0,0,6.77-21.87c0-21.56-16.33-41.38-36.3-44.18m13.63,81.24L137,150.1m-73,7.16,14.15-15.43m52.1,132.77,15.57-14.35m-90.59,3.81,14.48-14.5m-4-140.82,17-17.57'/>";
   } else if (uint256(keccak256(abi.encodePacked("RING", currentToken))) % 33 > 4 && uint256(keccak256(abi.encodePacked("RING", currentToken))) % 33 < 13) {
     currentRing = ["ring-3", "24"];
     svgDoor = "<path class='shadow-rear' d='M173.43,242.21l-78.2-11L95,93.09s.52-6.48,5.6-14.86c4.67-7.73,14.25-18.72,33.43-27.29,19.21,14,28.84,27.67,33.54,36.7,5.09,9.81,5.64,16.39,5.65,16.46Z'><animate attributeName='opacity' values='0.15;0.75;0.15' dur='2.3s' repeatCount='indefinite'/></path><path class='shadow-mid op-light' d='M164.1,251.54l-78.2-11-.26-138.12s.52-6.48,5.6-14.86c4.67-7.73,14.25-18.72,33.43-27.29,19.21,14,28.84,27.66,33.54,36.7,5.09,9.81,5.64,16.39,5.65,16.46Z'><animate attributeName='opacity' values='0.15;0.75;0.15' dur='1.5s' repeatCount='indefinite'/></path><path class='shadow-front op-light' d='M154.77,260.87l-78.2-11-.25-138.12s.52-6.48,5.59-14.86c4.67-7.73,14.25-18.72,33.43-27.29,19.22,14,28.84,27.66,33.54,36.7,5.09,9.81,5.64,16.39,5.65,16.46Z'><animate attributeName='opacity' values='0.15;0.75;0.15' dur='2s' repeatCount='indefinite'/></path><path class='door-stroke fg-color no-fill' d='M133.42,282.06l-78.2-11L55,133s.53-6.48,5.6-14.86C65.22,110.36,74.8,99.37,94,90.8c19.22,14,28.85,27.66,33.54,36.7,5.1,9.81,5.65,16.4,5.65,16.46l.25,138.1M105.82,78.33l-.12,0c-19.37,8.63-29,19.74-33.76,27.55-5.11,8.48-5.63,15-5.64,15.08l.26,138.69,79.22,11.13-.26-138.66c0-.09-.55-6.78-5.7-16.7-4.73-9.13-14.46-23-33.88-37l-.12-.09M94,90.8,105.7,78.38m27.72,203.68,12.36-11.23m-90.56.24L66.56,259.7'/>";
   } else {
     currentRing = ["ring-4", "17"];
     svgDoor = "<path class='shadow-rear' d='M171.59,234.73l-78.08-11L93.3,110c0-15.49,3.32-35.89,19.43-45.22a34.85,34.85,0,0,1,19.51-4.48,44.78,44.78,0,0,1,19.53,10c8.92,7.64,19.55,22.65,19.6,50.7Z'><animate attributeName='opacity' values='0.15;0.75;0.15' dur='2.3s' repeatCount='indefinite'/></path><path class='shadow-mid op-light' d='M162.93,243.39l-78.08-11-.21-113.74c0-15.48,3.31-35.89,19.42-45.21A34.75,34.75,0,0,1,123.57,69a44.47,44.47,0,0,1,19.54,10c8.91,7.64,19.55,22.64,19.6,50.7Z'><animate attributeName='opacity' values='0.15;0.75;0.15' dur='1.5s' repeatCount='indefinite'/></path><path class='shadow-front op-light' d='M154.26,252.06l-78.08-11L76,127.35c0-15.49,3.32-35.89,19.42-45.21a34.78,34.78,0,0,1,19.51-4.48,44.51,44.51,0,0,1,19.54,10c8.92,7.64,19.55,22.65,19.6,50.7Z'><animate attributeName='opacity' values='0.15;0.75;0.15' dur='2s' repeatCount='indefinite'/></path><path class='door-stroke fg-color no-fill' d='M133.24,272.77l-78.08-11L55,148.07c0-15.49,3.32-35.9,19.42-45.21a35,35,0,0,1,19.52-4.49,44.6,44.6,0,0,1,19.54,10C122.34,116,133,131,133,159l.21,113.73M106.07,85.67A35.44,35.44,0,0,0,86.32,90.2c-9,5.2-19.71,17.33-19.66,45.62l.22,114.24,79,11.1-.21-114.24c0-15.62-3.5-37.17-19.84-51.16a45.27,45.27,0,0,0-19.78-10.09m27.17,187.1,12.66-11.61m-90.74.64,11.72-11.74m1.36-142.72L81.31,93.6'/>";
   }

   string memory svgStyle = string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 200 333'><defs><style>.bg-color{fill:#e9e8e1;}.no-fill{fill:none;}.fg-color{stroke:#2a383e;}.font{font-size:12.77px;font-family:monospace;}.fg-fill{fill:#2a383e;}.shadow-rear{fill:#",doorMetaData[53],";opacity:0.75;}.shadow-mid{fill:#",doorMetaData[54],";}.op-light{opacity:0.5;}.shadow-front{fill:#",doorMetaData[55],";}.door-stroke{stroke-linecap:round;stroke-width:1.2px;}.stroke-width-sm{stroke-width:0.75px;}.",currentRing[0],"{fill:#",doorMetaData[53],";fill-opacity:0.75;}</style></defs>"));

   string memory svgFrameOpen = string(abi.encodePacked("<g id='Layer_2' data-name='Layer 2'><g id='Layer_1-2' data-name='Layer 1'><rect class='bg-color' width='200' height='333' rx='8'/><path class='fg-color no-fill' d='M26.38,20h147.2c3.53,0,6.4,3.15,6.4,7V305.94c0,3.88-2.87,7-6.4,7H26.38c-3.54,0-6.4-3.16-6.4-7V27C20,23.13,22.84,20,26.38,20Z' stroke-dashoffset='10' stroke-dasharray='10 10'><animate attributeName='stroke-dashoffset' values='0 ; 100' dur='15s' repeatCount='indefinite' /></path><path class='fg-color no-fill' d='M26.38,20h147.2c3.53,0,6.4,3.15,6.4,7V305.94c0,3.88-2.87,7-6.4,7H26.38c-3.54,0-6.4-3.16-6.4-7V27C20,23.13,22.84,20,26.38,20Z' stroke-dashoffset='7' stroke-dasharray='7 7'><animate attributeName='stroke-dashoffset' values='0 ; 100' dur='10s' repeatCount='indefinite' /></path><path class='fg-color no-fill' d='M26.38,20h147.2c3.53,0,6.4,3.15,6.4,7V305.94c0,3.88-2.87,7-6.4,7H26.38c-3.54,0-6.4-3.16-6.4-7V27C20,23.13,22.84,20,26.38,20Z' stroke-dashoffset='2' stroke-dasharray='2 2'><animate attributeName='stroke-dashoffset' values='0 ; 100' dur='7s' repeatCount='indefinite' /></path><rect class='bg-color' x='27.71' y='18.39' width='",currentRing[1],"' height='3.17'/><rect class='bg-color' x='71.84' y='311.13' width='56.29' height='3.88'/><text class='fg-fill font' transform='translate(28.21 26.12)'>", doorMetaData[uint256(keccak256(abi.encodePacked("RING", currentToken))) % 33] ,"<tspan x='0' y='15.33'>", doorMetaData[33 +uint256(keccak256(abi.encodePacked("ELEMENT", currentToken))) % 16] ,"</tspan><tspan x='0' y='30.66'>", doorMetaData[49 + uint256(keccak256(abi.encodePacked("SUIT", currentToken))) % 4] ,"</tspan></text>"));

   string memory svgFrameClose = string(abi.encodePacked("<path class='stroke-width-sm fg-color bg-color' d='M123.33,317.81c-2.23,2.68-6.84,4.68-12.5,5.75l-.51.09v-3.34l.51-.09c1.17-.22,2.3-.48,3.38-.78.44-.12.88-.26,1.3-.39a24.82,24.82,0,0,0,4.3-1.82h0a12.21,12.21,0,0,0,3.52-2.75v3.33'/><line class='stroke-width-sm fg-color no-fill' x1='110.83' y1='323.56' x2='110.83' y2='323.56'/><path class='stroke-width-sm fg-color bg-color' d='M78,318.16v-3.33h0a17.56,17.56,0,0,0,4,2.57,29.17,29.17,0,0,0,2.73,1.13,35.25,35.25,0,0,0,3.49,1.05c1.2.3,2.48.57,3.82.79v3.33c-6.41-1.05-11.31-3.09-14-5.54'/><path class='stroke-width-sm fg-color bg-color' d='M78,318.16h0'/><path class='no-fill stroke-width-sm fg-color ring-4' d='M124.66,311.65a4.86,4.86,0,0,1-.28,1.09,6.72,6.72,0,0,1-1,1.74,12.21,12.21,0,0,1-3.52,2.75h0a24.82,24.82,0,0,1-4.3,1.82c-.42.13-.86.27-1.3.39-1.08.3-2.21.56-3.38.78l-.51.09c-.87.16-1.77.29-2.68.4h0a52.79,52.79,0,0,1-6.37.38,56.73,56.73,0,0,1-6.74-.37c-.83-.1-1.66-.22-2.48-.35-1.34-.22-2.62-.49-3.82-.79a35.25,35.25,0,0,1-3.49-1.05A29.17,29.17,0,0,1,82,317.4a17.56,17.56,0,0,1-4-2.57h0a7.86,7.86,0,0,1-2.15-2.92,4.79,4.79,0,0,1-.3-1.27,5.34,5.34,0,0,1,0-.8,5.6,5.6,0,0,1,1.35-3c2.23-2.68,6.84-4.68,12.5-5.74a55.66,55.66,0,0,1,18.78-.15c6.41,1.06,11.31,3.1,14,5.54h0a6.81,6.81,0,0,1,2.43,4A4.43,4.43,0,0,1,124.66,311.65Z'/><line class='stroke-width-sm fg-color no-fill' x1='108.18' y1='300.95' x2='92.05' y2='320.37'/><line class='stroke-width-sm fg-color no-fill' x1='123.33' y1='314.48' x2='76.9' y2='306.84'/><line class='stroke-width-sm fg-color no-fill' x1='110.83' y1='320.22' x2='89.4' y2='301.1'/><polyline class='stroke-width-sm fg-color no-fill' points='122.23 306.49 122.23 306.49 118.22 307.25 117.3 307.42 113.46 308.14 113 308.23 111.95 308.43 110.49 308.71 108.77 309.03 107.22 309.32 105.75 309.6 105.22 309.7 103.93 309.94 103.4 310.04 103.4 310.04 100.19 310.65 100.17 310.65 100.15 310.65 100.13 310.66 100.11 310.66 100.02 310.68 99.97 310.69 99.83 310.71 99.59 310.76 99.49 310.78 97.05 311.24 97.03 311.24 94.32 311.75 94.28 311.76 93.87 311.84 93.01 312 90.7 312.43 90.67 312.44 89.74 312.61 88.84 312.78 86.77 313.18 85.3 313.45 82.93 313.9 81.2 314.22 81.07 314.25 78 314.83'/><path class='stroke-width-sm fg-color bg-color' d='M123.33,317.81v-3.33a6.72,6.72,0,0,0,1-1.74,4.86,4.86,0,0,0,.28-1.09V315a5.64,5.64,0,0,1-1.33,2.83'/><path class='stroke-width-sm fg-color bg-color' d='M78,318.16A6.66,6.66,0,0,1,75.55,314v-3.35a4.79,4.79,0,0,0,.3,1.27A7.86,7.86,0,0,0,78,314.83v3.33'/><path class='stroke-width-sm fg-color bg-color' d='M110.32,320.31v3.34a55.92,55.92,0,0,1-18.27.05v-3.33c.82.13,1.65.25,2.48.35a56.73,56.73,0,0,0,6.74.37,52.79,52.79,0,0,0,6.37-.38h0C108.55,320.6,109.45,320.47,110.32,320.31Z'/><ellipse class=' stroke-width-sm fg-color bg-color ring-3' cx='100.12' cy='310.66' rx='8.1' ry='19.09' transform='matrix(0.02, -1, 1, 0.02, -212.56, 404.29)'/><path class=' stroke-width-sm fg-color bg-color' d='M100.12,310.66l12.53-5.89-12.53,5.89-12.54,5.89Z'/><path class=' stroke-width-sm fg-color bg-color' d='M100.12,310.66l19-.23-19,.23-19.05.23Z'/><path class=' stroke-width-sm fg-color bg-color' d='M100.12,310.66l14.39,5.56-14.39-5.56-14.4-5.56Z'/><path class=' stroke-width-sm fg-color bg-color' d='M100.12,310.66l1.31,8.1-1.31-8.1-1.32-8.1Z'/><ellipse class=' stroke-width-sm fg-color bg-color ring-2' cx='100.12' cy='310.66' rx='6.29' ry='14.84' transform='translate(-212.56 404.29) rotate(-88.81)'/><line class=' stroke-width-sm fg-color no-fill' x1='104.98' y1='304.8' x2='95.27' y2='316.5'/><line class=' stroke-width-sm fg-color no-fill' x1='113.45' y1='308.14' x2='86.8' y2='313.16'/><line class=' stroke-width-sm fg-color no-fill' x1='114.11' y1='312.95' x2='86.14' y2='308.35'/><line class=' stroke-width-sm fg-color no-fill' x1='106.58' y1='316.41' x2='93.67' y2='304.89'/><ellipse class=' stroke-width-sm fg-color bg-color ring-1' cx='100.12' cy='310.66' rx='4.89' ry='11.53' transform='translate(-212.56 404.29) rotate(-88.81)'/><line class=' stroke-width-sm fg-color no-fill' x1='107.57' y1='307.13' x2='92.36' y2='314.18'/><line class=' stroke-width-sm fg-color no-fill' x1='111.43' y1='310.54' x2='88.49' y2='310.76'/><line class=' stroke-width-sm fg-color no-fill' x1='108.58' y1='314.03' x2='91.34' y2='307.28'/><line class=' fg-color no-fill' x1='100.68' y1='315.53' x2='99.25' y2='305.77'/><ellipse class=' stroke-width-sm fg-fill fg-color' cx='100.12' cy='310.66' rx='3.35' ry='7.9' transform='translate(-212.56 404.29) rotate(-88.81)'/><line class=' stroke-width-sm fg-color no-fill' x1='110.32' y1='323.82' x2='110.32' y2='323.65'/><line class=' stroke-width-sm fg-color no-fill' x1='110.32' y1='320.31' x2='110.32' y2='320.13'/><g><ellipse class=' stroke-width-sm fg-fill' cx='99.96' cy='306.37' rx='7.17' ry='7.93' transform='translate(-220.38 341.52) rotate(-78.19)'/><path class='bg-color' d='M104.17,302.43a3.42,3.42,0,0,0-.59-.33,1.39,1.39,0,0,0-1-.07c-.89.33-.27,1.23.2,1.65a4.89,4.89,0,0,1,.82.82c.5.73,0,1.38-.35,2a1.28,1.28,0,0,0,.34,1.82c1.12.72,2.12-.38,2.37-1.28a4.17,4.17,0,0,0-.37-2.95c0-.1-.1-.2-.16-.3A4.82,4.82,0,0,0,104.17,302.43Z'/><animateTransform attributeType='xml' attributeName='transform' type='translate' dur='15s' values='0 0 ; 0 -12 ; 0 -10 ; 0 -12 ; 0 -10 ; 0 -12; 0 0; 0 -2; 0 0;' repeatCount='indefinite' calcMode='bezier'/></g></g></g></svg>"));
    return Base64.encode(
        bytes(
            string(
                abi.encodePacked(
                    '{"description": "The inaugural launch of Meta User Dungeon (Cycle 0 - Enter the Void) consists of a series of 4179 programatically generated on-chain SVG tokens.", "external_url": "https://metadungeon.quest/doors", "image": "data:image/svg+xml;base64,',
                    Base64.encode(bytes(abi.encodePacked(svgStyle,svgFrameOpen,svgDoor,svgFrameClose))),
                    '","name": "Meta User Dungeon #',(currentToken + 1).toString(),'", "attributes": [{"trait_type":"ring", "value":"', doorMetaData[uint256(keccak256(abi.encodePacked("RING", currentToken))) % 33] ,'"},{"trait_type":"element", "value":"', doorMetaData[33 +uint256(keccak256(abi.encodePacked("ELEMENT", currentToken))) % 16] ,'"}, {"trait_type":"suit", "value":"', doorMetaData[49 +uint256(keccak256(abi.encodePacked("SUIT", currentToken))) % 4] ,'"}]}'
                )
            )
        )
    );
  }
}