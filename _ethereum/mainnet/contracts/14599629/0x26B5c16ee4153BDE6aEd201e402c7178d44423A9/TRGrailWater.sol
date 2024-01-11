// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "./TRKeys.sol";

/// @notice The Reliquary Grail of Water
library TRGrailWater {

  function getElement() public pure returns (string memory) {
    return 'Water';
  }

  function getPalette() public pure returns (string memory) {
    return 'Opalescent';
  }

  function getEssence() public pure returns (string memory) {
    return 'Undine';
  }

  function getStyle() public pure returns (string memory) {
    return 'Sketch';
  }

  function getSpeed() public pure returns (string memory) {
    return 'Hyper';
  }

  function getGravity() public pure returns (string memory) {
    return 'Atmospheric';
  }

  function getDisplay() public pure returns (string memory) {
    return 'Normal';
  }

  function getColorCount() public pure returns (uint256) {
    return 4;
  }

  function getRelicType() public pure returns (string memory) {
    return TRKeys.RELIC_TYPE_GRAIL;
  }

  function getRuneflux() public pure returns (uint256) {
    return 999;
  }

  function getCorruption() public pure returns (uint256) {
    return 904;
  }

  function getGlyph() public pure returns (uint256[] memory) {
    uint256[] memory glyph = new uint256[](64);
    glyph[0]  = uint256(0);
    glyph[1]  = uint256(0);
    glyph[2]  = uint256(0);
    glyph[3]  = uint256(0);
    glyph[4]  = uint256(0);
    glyph[5]  = uint256(0);
    glyph[6]  = uint256(0);
    glyph[7]  = uint256(0);
    glyph[8]  = uint256(0);
    glyph[9]  = uint256(0);
    glyph[10] = uint256(0);
    glyph[11] = uint256(0);
    glyph[12] = uint256(0);
    glyph[13] = uint256(0);
    glyph[14] = uint256(0);
    glyph[15] = uint256(0);
    glyph[16] = uint256(0);
    glyph[17] = uint256(0);
    glyph[18] = uint256(990090009009009000000000000000000000000);
    glyph[19] = uint256(900090099009090090009900000000000000000000);
    glyph[20] = uint256(990990090000000000000099000000000000000000000);
    glyph[21] = uint256(90090009999999999900990000000000000000000000);
    glyph[22] = uint256(9000990000000000090000090000000000000000000);
    glyph[23] = uint256(900009000000000000009000990000000000000000000);
    glyph[24] = uint256(900090999990000999900900900000000000000000000);
    glyph[25] = uint256(90909009099009090090900000000000000000000000);
    glyph[26] = uint256(909009099009090090090099000000000000000000);
    glyph[27] = uint256(900999990000999900090990000000000000000000);
    glyph[28] = uint256(9900000000000000000090000000000000000000000);
    glyph[29] = uint256(9909009900090000090000900000000000000000000000);
    glyph[30] = uint256(900999900990000990009009000000000000000000000);
    glyph[31] = uint256(99900999909009099090099000000000000000000000);
    glyph[32] = uint256(99090099009090009990990000000000000000000000);
    glyph[33] = uint256(9999999999990909000000000000000000000000);
    glyph[34] = uint256(900000000000000000000000000000000);
    glyph[35] = uint256(999990000000099999000000000000000000000000);
    glyph[36] = uint256(9999000000999900000000000000000000000000);
    glyph[37] = uint256(9990000000000000000000000000000000);
    glyph[38] = uint256(90099000009999000000000000000000000000);
    glyph[39] = uint256(9999099099900900000000000000000000000000);
    glyph[40] = uint256(90009990990000000000000000000000000000);
    glyph[41] = uint256(9099090000000000000000000000000000);
    glyph[42] = uint256(99009990000000000000000000000000000);
    glyph[43] = uint256(990009000000000000000000000000000000);
    glyph[44] = uint256(900099000000000000000000000000000000);
    glyph[45] = uint256(999990000000000000000000000000000000);
    glyph[46] = uint256(0);
    glyph[47] = uint256(0);
    glyph[48] = uint256(0);
    glyph[49] = uint256(0);
    glyph[50] = uint256(0);
    glyph[51] = uint256(0);
    glyph[52] = uint256(0);
    glyph[53] = uint256(0);
    glyph[54] = uint256(0);
    glyph[55] = uint256(0);
    glyph[56] = uint256(0);
    glyph[57] = uint256(0);
    glyph[58] = uint256(0);
    glyph[59] = uint256(0);
    glyph[60] = uint256(0);
    glyph[61] = uint256(0);
    glyph[62] = uint256(0);
    glyph[63] = uint256(0);
    return glyph;
  }

  function getDescription() public pure returns (string memory) {
    return 'The Grail of Water honors Studio Mathcastles. Their boundary-shattering commitment to the medium of runtime arts has been both a great pleasure to witness and an inspiration to my craft; they have changed the way I think about both art and software, and for that I am forever grateful.';
  }

}
