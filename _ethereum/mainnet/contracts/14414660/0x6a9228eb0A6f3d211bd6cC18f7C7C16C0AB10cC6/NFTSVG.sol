// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.11;

import "./Strings.sol";

library NFTSVG {
  using Strings for uint256;

  struct SVGParams {
    uint256 tokenId;
    uint256 block;
    address owner;
  }

  function generateSVG(SVGParams memory params) internal view returns (string memory svg) {
    ( , string memory base ) = idToColor(params.tokenId + 1, params.tokenId, params.owner);

    return
      string(
        abi.encodePacked(
          '<svg version="1.1" width="580" height="580" viewBox="0 0 580 580" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
          '<rect width="580" height="580" x="0" y="0" fill="',
          base,
          '" />',
          _generateSVGPaths(params),
          '</svg>'
        )
      );
  }

  function _generateSVGPaths(SVGParams memory params) private view returns (string memory svgPaths) {
    string memory svgPaths;

    uint256 pos_x = 40;
    uint256 pos_y = 40;
    uint256 w = 80;
    uint256 po = 40;
    ( uint256 width, string memory base ) = idToColor(params.tokenId, params.tokenId + 1, params.owner);

    for(uint256 r = 0; r < 10; ++r){
      pos_x = 40;
      for(uint256 c = 0; c < 10; ++c){
        ( uint256 duration, string memory rgb ) = idToColor(params.tokenId, r*c+pos_x*pos_y*pos_y+pos_x+r, params.owner);
        //( uint256 duration2, string memory rgb2 ) = idToColor(params.tokenId, r*c+duration, params.owner);
        string memory pattern = string(abi.encodePacked(rgb, ';', base, ';', rgb));
        svgPaths = string(abi.encodePacked(
          svgPaths,
          '<rect width="',
          (duration+w).toString(),
          '" height="',
          (duration+w).toString(),
          '" x="',
          pos_x.toString(),
          '" y="',
          pos_y.toString(),
        //  '" style="stroke-width:3;stroke:rgb(0,0,0)">',

          // '<animateTransform attributeName="transform" type="scale" from="0.1" to="7.9" dur="',
          // (duration + c).toString(),
          // 's" repeatCount="indefinite" />'
          '" opacity=".2" rx="',
          (duration/4).toString(),
          '"><animate attributeName="fill" values="',
          pattern,
          '" dur="',
          (3+(duration/(c+1))).toString(),
          's" repeatCount="indefinite" /></rect>'
        ));
        pos_x = pos_x + po;
      }
      pos_y = pos_y + po;
    }

    return svgPaths;
  }

  function idToColor(uint256 _id, uint256 _cell, address _owner) public view returns (uint256, string memory) {
    uint256 seed = uint256(keccak256(abi.encodePacked(_id, _owner, _cell, address(this))));

    uint256 firstChunk = seed % 256;
    uint256 secondChunk = ((seed - firstChunk) / 256) % 256;
    uint256 thirdChunk = ((((seed- firstChunk) / 256) - secondChunk ) / 256) % 256;

    string memory rgbString = string(abi.encodePacked(
      'rgb(',
      firstChunk.toString(),
      ', ',
      secondChunk.toString(),
      ', ',
      thirdChunk.toString(),
      ')'
    ));

    if(thirdChunk > secondChunk){
      if(thirdChunk - secondChunk < 10){
        rgbString = string(abi.encodePacked('rgb(0,0,255)'));
      }
    }

    firstChunk = 256 - firstChunk;

    return (10 + (firstChunk * firstChunk % 64), rgbString);
   }
}
