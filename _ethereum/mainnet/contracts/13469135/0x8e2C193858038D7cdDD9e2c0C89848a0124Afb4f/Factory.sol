//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";
import "./ITheCreepz.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./IFactoryDescriptor.sol";

contract Factory {
    using Strings for uint256;

    address private immutable _extendDescriptor;

    constructor(address _extendDescriptor_) public {

      _extendDescriptor = _extendDescriptor_;

      art._fills = [
        'transform-origin: center;  stroke:black; stroke-width:5; stroke-linecap: round;fill:none; opacity:0.5;} ',
        'fill:black;opacity:0.25;transform-origin: center;} '
      ];

      art._bgAnims = [
          "8s bg infinite alternate ease-in-out; } @keyframes bg { 50% { transform: translateX(15%); } 100% { transform: translateX(-15%); }}",
          "8s bg infinite alternate ease-in-out; } @keyframes bg { from { transform: translateX(25%); } to { transform:translateX(-25%); }}",
          "8s bg infinite alternate ease-in-out; } @keyframes bg { from { transform: translateX(50%); } to { transform: translateX(-50%); }}",
          "8s bg infinite alternate ease-in-out; } @keyframes bg { from { transform:translateX(-150%); } to { transform:translateX(150%); }}",
          "8s bg infinite alternate ease-in-out; transform-origin:center; } @keyframes bg { 25% { transform:rotate(10deg); } 50% { transform: rotate(-10deg); } 75% { transform: rotate(10deg); } 100% { transform: rotate(-10deg); }}",
          "16s bg infinite alternate ease-in-out; transform-origin:center; } @keyframes bg { 10% { transform:rotate(15deg); } 100% { transform:rotate(-360deg); }}",
          "16s bg ease-in-out normal infinite; transform-origin:center; } @keyframes bg { 25% { transform:rotate(-15deg); } 100% { transform:rotate(360deg); }}",
          "8s bg infinite alternate ease-in-out; } @keyframes bg { from { transform:translateY(25%); } to { transform:translateY(-25%); }}"
        ];

      art._faceAnims = [
        "8s alternate; } @keyframes faceAnim { 50% { transform: translateY(-15%) } 100% { transform:translateY(10%) }} ",
        "8s alternate; } @keyframes faceAnim { 50% { transform: translateY(15%) } 100% { transform:translateY(-10%) }} ",
        "8s alternate; } @keyframes faceAnim { 50% { transform: translateX(-15%) } 100% { transform:translateX(15%) }} ",
        "8s alternate; } @keyframes faceAnim { 50% { transform: translateX(15%) } 100% { transform:translateX(-15%) }} ",
        "8s alternate; } @keyframes faceAnim { 50% { transform:translate(20%,20%) } 100% {transform:translate(-20%,-20%) }} ",
        "8s alternate; } @keyframes faceAnim { 50% { transform:translate(-20%,20%) } 100% {transform:translate(20%,-20%) }} ",
        "8s alternate; } @keyframes faceAnim { 50%{transform:rotate(-45deg) } 100% { transform:rotate(45deg) }} ",
        "4s alternate; } @keyframes faceAnim { 50% { transform: scale(.95) } 100% { transform:scale(1.05) }} ",
        "8s normal; } @keyframes faceAnim { 0% { transform:rotate(0deg)} 75% { transform:rotate(9deg) } 90% { transform:rotate(-7deg) } 100% { transform:rotate(0deg) }} ",
        "8s normal; } @keyframes faceAnim { 0% { transform:rotate(0deg)} 75% { transform:rotate(-9deg) } 90% { transform:rotate(7deg) } 100% { transform:rotate(0deg) }} ",
        "8s normal; } @keyframes faceAnim { 0% { transform:translate(10%,10%) } 25% { transform:translate(10%,-10%) } 50% { transform:translate(-10%,-10%)}75%{transform:translate(-10%,10%)}100%{transform:translate(10%,10%) }} ",
        "8s normal; } @keyframes faceAnim { 0% { transform:translate(10%,10%) } 25% { transform:translate(-10%,10%) } 50% { transform:translate(-10%,-10%)}75%{transform:translate(10%,-10%)}100%{transform:translate(10%,10%) }} "
      ];


    }

    struct Art {
      string[] _fills;
      string[] _bgAnims;
      string[] _faceAnims;
    }
    Art art;

    //
    function getCreepz(ITheCreepz.Creepz memory _dna) public view  returns (string memory) {
        return IFactoryDescriptor(_extendDescriptor).getCreepz(_dna);
    }
    function getDefs(ITheCreepz.Creepz memory _dna) public view  returns (string memory) {
        return IFactoryDescriptor(_extendDescriptor).getDefs(_dna);
    }
    function getArtItems(ITheCreepz.Creepz memory _dna) public view  returns (string[17] memory) {
        return IFactoryDescriptor(_extendDescriptor).getArtItems(_dna);
    }
    //
    function stringToBytes( string memory s) internal pure returns (bytes memory){
        bytes memory b3 = bytes(s);
        return b3;
    }
    //
    function styles(ITheCreepz.Creepz memory _dna, uint256 _tokenId) internal view returns (string memory) {



      string memory scales;

      if(_dna.bg < 6){
        for (uint256 i = 0; i < _dna.bgLen; i++) {
          if(i == 0){
            scales = string(abi.encodePacked(scales,
                " .s",i.toString(),"{transform:scale(1);}"
            ));
          } else {
            scales = string(abi.encodePacked(scales,
                " .s",i.toString(),"{ transform:scale(0.",(10-i).toString(),"); }"
            ));
          }

        }
        scales = string(abi.encodePacked(scales,
          "#creepz", _tokenId.toString()," .f { transform-box: fill-box;",art._fills[_dna.bgFill],
          "#creepz", _tokenId.toString()," .bg { animation:",art._bgAnims[_dna.bgAnim]
        ));
      }
      if(_dna.bg == 6){
        scales = string(abi.encodePacked(
          "#creepz", _tokenId.toString()," .f { transform-box: fill-box;",art._fills[_dna.bgFill],
          "#creepz", _tokenId.toString()," .bg { animation:3s bg infinite alternate ease-in-out}@keyframes bg { from { transform:translateX(25%)} to { transform:translateX(-25%)}} "
        ));
      }
      if(_dna.bg == 7){
        scales = string(abi.encodePacked(
          "#creepz", _tokenId.toString()," .f { transform-box: fill-box;",art._fills[_dna.bgFill],
          "#creepz", _tokenId.toString()," .bg { animation:8s bg infinite alternate ease-in-out}@keyframes bg { 0% { transform:translateX(0)} 50% { transform:translateX(-10%)} 100% { transform:translateX(10%)}} ",
          " .delay0 { animation-delay:0s } .delay1 { animation-delay:.2s } .delay2 { animation-delay:.4s } .delay3 { animation-delay:.6s } .delay4 { animation-delay:.8s } "
        ));
      }
      if(_dna.bg == 8){
        scales = string(abi.encodePacked(
          "#creepz", _tokenId.toString()," .f { stroke-dasharray:3000; stroke-dashoffset:1000; opacity:.5; transform-origin:center; transform-box:fill-box; stroke:#000; stroke-width:24; stroke-linecap:round; fill:none } ",
          "#creepz", _tokenId.toString()," .bg { animation:bg 16s ease-in-out alternate infinite,rotate 16s infinite alternate ease-in-out;} ",
          "@keyframes bg { 0% { stroke-dashoffset:3000 } 100% { stroke-dashoffset:0 }} ",
          "@keyframes rotate { from { transform:rotate(360deg) } to { transform:rotate(-360deg)}} "
        ));
      }



      return string(abi.encodePacked(
        "<style>",
          scales,
          "#creepz", _tokenId.toString()," .rgb { filter: contrast(120%) saturate(120%); } ",
          "#creepz", _tokenId.toString()," .hue { animation: hue 16s infinite; } @keyframes hue {0% { filter:hue-rotate(0deg); } 50% { filter: hue-rotate(45deg); } 100% { filter:hue-rotate(0deg); }} ",
          "#creepz", _tokenId.toString()," .body-fill { fill: url('#gradBody'); } ",
          "#creepz", _tokenId.toString()," .bodyAnim { transform-box: fill-box; transform-origin: center; animation: 4s bodyAnim infinite alternate ease-in-out; } @keyframes bodyAnim { from { transform: scale(1); } to { transform: scale(1.1); }} ",
          "#creepz", _tokenId.toString()," .face-fill { fill: url('#gradFace'); }",
          "#creepz", _tokenId.toString()," .faceAnim { transform-box:fill-box; transform-origin:center; animation:faceAnim infinite ease-in-out ",art._faceAnims[_dna.faceAnim],
          "#creepz", _tokenId.toString()," .blink { animation:2.9s blink infinite; } @keyframes blink { 85% { clip-path:ellipse(100% 100%); animation-timing-function:ease-in } 89% { clip-path:ellipse(10% 0); } 100% { animation-timing-function:ease-out; }}"
        "</style>"
      ));
    }
    function layers(uint8 nb, uint8 bg) public pure returns (string memory) {
      string memory anim;

      if(bg < 6){
        for (uint256 i; i < nb; i++) {
          anim = string(abi.encodePacked(anim,
              "<g class='s",i.toString(),"' transform-origin='center'><use class='f bg' href='#bgAnim' /></g>"
          ));
        }
        return anim;
      }
      if(bg == 6){
        string[6] memory mountain = ["M193.5 8L325 320H62L193.5 8Z","M90 47L205 320H-25L90 47Z","M13 123L96 320H-70L13 123Z","M268.057 75.5L371.114 320H165L268.057 75.5Z","M312.5 237.5L347.5 320H277.5L312.5 237.5Z","M193.5 157L262 320H125L193.5 157Z"];
        for (uint256 i; i < nb; i++) {
          anim = string(abi.encodePacked(anim,
              "<path class='f bg' d='",mountain[i],"'/>"
          ));
        }
        return anim;
      }
      if(bg == 7){
        string[5] memory sea = [
              "M-101.5,124c42.9,0,19.5,59.9,53.1,62.6,28.5,2.2,34.7-41.7,63.3-40.4,30.1,1.4,30.9,33.9,61,36.2,39.8,3,47.4-49.6,86.9-43.7,27.7,4.1,29.7,40.3,57.7,39.6s34.7-44.3,61.3-39.6c17,3,29.3,19,46.4,21.9,24.5,4.1,10.9-36.6,52.3-36.6V375h-482Z",
              "M-56.5,147.5c42.9,0,19.5,54.4,53.1,56.8,28.5,2.1,34.7-37.8,63.3-36.6,30.1,1.3,30.9,30.8,61,32.9,39.8,2.7,47.4-45.1,86.9-39.7,27.7,3.7,29.7,36.6,57.7,35.9s34.7-40.3,61.3-35.9c17,2.7,29.3,17.2,46.4,19.8,24.5,3.7,10.9-33.2,52.3-33.2v228h-482Z",
              "M-114,175.5c42.9,0,19.5,47.7,53.1,49.9,28.5,1.8,34.7-33.2,63.3-32.2,30.1,1.1,30.9,27,61,28.8,39.8,2.4,47.4-39.5,86.9-34.8,27.7,3.3,29.7,32.1,57.7,31.5s34.7-35.3,61.3-31.5c17,2.4,29.3,15.2,46.4,17.4,24.5,3.3,10.9-29.1,52.3-29.1v200H-114Z",
              "M-56.5,203.5c42.9,0,19.5,41,53.1,42.9,28.5,1.5,34.7-28.6,63.3-27.7,30.1,1,30.9,23.3,61,24.8,39.8,2.1,47.4-33.9,86.9-29.9,27.7,2.8,29.7,27.6,57.7,27.1s34.7-30.4,61.3-27.1c17,2,29.3,13,46.4,15,24.5,2.8,10.9-25.1,52.3-25.1v172h-482Z",
              "M-122.5,226c42.9,0,19.5,35.7,53.1,37.3,28.5,1.3,34.7-24.9,63.3-24.1s30.9,20.2,61,21.6c39.8,1.8,47.4-29.5,86.9-26,27.7,2.4,29.7,24,57.7,23.5s34.7-26.4,61.3-23.5c17,1.8,29.3,11.3,46.4,13,24.5,2.4,10.9-21.8,52.3-21.8V375.5h-482Z"
            ];
        for (uint256 i; i < nb; i++) {
          anim = string(abi.encodePacked(anim,
              "<path class='f bg delay",i.toString(),"' d='",sea[i],"'/>"
          ));
        }
        return anim;
      }
      if(bg == 8){
        for (uint256 i = 1; i < nb+1; i++) {
          anim = string(abi.encodePacked(anim,
              "<circle class='f bg' cx='160' cy='160' r='",(225-i*25).toString(),"'/>"
          ));
        }
        return anim;
      }
      return "";
    }



    function imageData(ITheCreepz.Creepz memory dna, uint256 _tokenId) public view returns (string memory) {

      string memory image = string(abi.encodePacked(
        "<svg id='creepz", _tokenId.toString(), "' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='320' height='320' viewBox='0 0 320 320' xml:space='preserve'>",
          styles(dna, _tokenId),
          "<g class='rgb'>",
            "<g filter='url(#grain)'>",
              "<g class='hue'>",
                "<rect id='bgColor' width='320' height='320' fill='url(#gradBg)'/>",
              "</g>",
            "</g>",
            layers(dna.bgLen,dna.bg),
            getCreepz(dna),
          "</g>",
          "<defs>",
            getDefs(dna),
          "</defs>",
        "</svg>"
      ));

      return string(abi.encodePacked("data:image/svg+xml;base64,",Base64.encode(stringToBytes(image))));
  	}
    //
    function tokenURI(ITheCreepz thecreepz, uint256 _tokenId) public view returns (string memory) {
      //
      ITheCreepz.Creepz memory dna = thecreepz.details(_tokenId);
      //
      string[17] memory artItems = getArtItems(dna);
      string[17] memory traitType = ["BACKGROUND COLOR-1","BACKGROUND COLOR-2", "BACKGROUND","BACKGROUND TYPE","BACKGROUND ANIMATION","BACKGROUND LAYERS", "BODY","BODY COLOR-1", "BODY COLOR-2", "FACE","FACE COLOR-1","FACE COLOR-2","FACE ANIM","EYE TYPE","EYES", "PUPILS","ACCESSORIES"];
      //
      string memory attributes;
      //
      for (uint256 i = 0; i < artItems.length; i++) {
        if (keccak256(bytes(artItems[i])) == keccak256(bytes(""))) continue;
        attributes = string(abi.encodePacked(attributes,
          bytes(attributes).length == 0	? '{' : ', {',
            '"trait_type": "', traitType[i],'",',
            '"value": "', artItems[i], '"',
          '}'
        ));
      }

      string memory json = Base64.encode(bytes(
        string(abi.encodePacked(
          '{',
            '"name": "Creepz #', _tokenId.toString(), '",',
            '"description": "The Creepz on-chain creatures.",',
            '"image": "', imageData(dna, _tokenId), '",',
            '"attributes": [', attributes, ']',
          '}'
        ))
      ));
      return string(abi.encodePacked('data:application/json;base64,', json));
    }

}
