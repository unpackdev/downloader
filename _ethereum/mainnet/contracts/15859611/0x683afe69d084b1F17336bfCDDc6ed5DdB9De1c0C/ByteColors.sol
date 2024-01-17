// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./IColors.sol";

contract ByteColors is IColors, Ownable
{
    bytes3[][] public palettes;
    bytes hexChars = "0123456789abcdef";

    string[] public skyColNames = ['Sunset Orange', 'Clear Blue', 'Storm Grey', 'Midnight Blue'];
    string[] public trailPaletteNames = [
        'Splurge', 'New Growth', 'Pink Velvet', 'Marshmallow', 'Space Station Lights', 'Gentle Dragon', 'Wood',
        'Clay Flora', 'Neon', 'Ultra Violetta', 'Powder Reveal', 'Pastel', 'Matured', 'Black & Yellow', 'Pure',
        'Emeralds', 'Yellow Bloom', 'Blue Flamed Log', 'Bausin'
    ];
    uint8[] public skyRarities = [ 32, 55, 73, 100 ];       //32%, 23%, 18%, 27%
    uint8[] public trailPaletteRarities = [ 3, 8, 15, 21, 29, 32, 35, 38, 45, 53, 60, 67, 71, 76, 83, 89, 94, 97, 100 ];

    bytes3[2][] public skyCols = [
        bytes3[2]([ bytes3(0xFF8252),  0xFD4470]),   //sunsetSky
        bytes3[2]([ bytes3(0xB2FBFF),  0x4FA9F2]),   //blueSky
        bytes3[2]([ bytes3(0x707078),  0x8da7be]),   //stormSky
        bytes3[2]([ bytes3(0x040643),  0x000000])    //nightSky
    ];

    constructor() {
        initData();
    }

    function initData() internal {
        //splurge
        palettes.push([ bytes3(0xff4b3e), 0x36213e, 0xc45baa, 0x32936f, 0xf7b801]);
        //New Growth
        palettes.push([ bytes3(0x264653), 0x2a9d8f, 0xe9c46a, 0xf4a261, 0xe76f51]);
        //pink velvet
        palettes.push([ bytes3(0xff0a54), 0xff477e, 0xff5c8a, 0xff7096, 0xff85a1, 0xff99ac, 0xfbb1bd, 0xf9bec7, 0xf7cad0, 0xfae0e4]);
        //marshmallow
        palettes.push([ bytes3(0xd8e2dc), 0xffe5d9, 0xffcad4, 0xf4acb7, 0x9d8189]);
        //space station lights
        palettes.push([ bytes3(0x2ebed9), 0x795ec1, 0x26e3e3, 0xe83de1, 0xf5f84b]);
        //gentle dragon
        palettes.push([ bytes3(0x433158), 0x8988a0, 0xe8d9be, 0xa87775, 0x6ba2c9, 0xe2dcde]);
        //wood
        palettes.push([ bytes3(0x6C4A35), 0x6d1f09, 0xa05d32, 0xcfa57b, 0xf6e9d6]);
        //clay flora
        palettes.push([ bytes3(0x8d2a00), 0xb55219, 0xbe6731, 0x76704c, 0x545e46, 0x1f2d16]);
        //neon
        palettes.push([ bytes3(0xf404cf), 0x90f505, 0x01f5bb, 0x037df4, 0xaf31f5, 0xF50561]);
        //ultra violetta
        palettes.push([ bytes3(0x2d00f7), 0x6a00f4, 0x8900f2, 0xa100f2, 0xb100e8, 0xbc00dd, 0xd100d1, 0xdb00b6, 0xe500a4, 0xf20089]);
        // powder reveal
        palettes.push([ bytes3(0xe574bc), 0xea84c9, 0xef94d5, 0xf9b4ed, 0xeabaf6, 0xdabfff, 0xc4c7ff, 0xadcfff, 0x96d7ff, 0x7fdeff]);
        //pastel
        palettes.push([ bytes3(0xff99c8), 0xfcf6bd, 0xd0f4de, 0xa9def9, 0xe4c1f9]);
        //matured
        palettes.push([ bytes3(0x001427), 0x708d81, 0xf4d58d, 0xbf0603, 0x8d0801]);
        //black & yellow
        palettes.push([ bytes3(0xd6d6d6), 0xffee32, 0xF5C800, 0x202020, 0x333533]);
        //pure
        palettes.push([ bytes3(0x000000), 0xffffff]);
        //emeralds
        palettes.push([ bytes3(0x03b5aa), 0x037971, 0x023436, 0x00bfb3, 0x049a8f]);
        //yellow bloom
        palettes.push([ bytes3(0xf9f0a1), 0xd8d085, 0x718f8d, 0x5ecbdf, 0x90e7f8, 0xc8f2fe]);
        // blue flamed log
        palettes.push([ bytes3(0xc6a477), 0xeed7a3, 0xf7ead7, 0xd3e7ee, 0xabd1dc, 0x7097a8]);
        //bausin
        palettes.push([ bytes3(0xc8823c), 0x1d181d, 0xbb5f36, 0x769ea0]);
    }

    //convert hex to string. each byte is 2 characters of the string
    //bit shift to get first 4 bits, and mask with 1111 to get remaining 4 bits
    //then use the number to lookup the character
    function getString(bytes3 b) internal view returns (string memory) {
        return string(abi.encodePacked(
                hexChars[ uint8(b[0]) >>4 ],
                hexChars[ uint8(b[0]) & 0xf ],
                hexChars[ uint8(b[1]) >>4 ],
                hexChars[ uint8(b[1]) & 0xf ],
                hexChars[ uint8(b[2]) >>4 ],
                hexChars[ uint8(b[2]) & 0xf ]
            ));
    }

    function getPalette(uint idx) external view virtual override returns (string[] memory) {
        bytes3[] storage palette = palettes[idx];
        string[] memory colors = new string[](palette.length);
        for(uint i=0; i < palette.length; i++) {
            colors[i] = getString(palette[i]);
        }
        return colors;
    }

    function getPaletteSize(uint idx) external view virtual override returns (uint) {
        return palettes[idx].length;
    }

    function getSkyPalette(uint idx) external view virtual override returns (string[] memory) {
        bytes3[2] storage palette = skyCols[idx];
        string[] memory colors = new string[](palette.length);
        for(uint i=0; i < palette.length; i++) {
            colors[i] = getString(palette[i]);
        }
        return colors;
    }

    function getNumSkys() external view virtual override returns (uint numSkys) {
        return skyCols.length;
    }

    function getNumPalettes() external view virtual override returns (uint numPalettes) {
        return trailPaletteNames.length;
    }

    function getSkyName(uint idx) external view virtual override returns (string memory name) {
        return skyColNames[idx];
    }

    function getPaletteName(uint idx) external view virtual override returns (string memory name) {
        return trailPaletteNames[idx];
    }

    function getSkyRarities() external view virtual override returns (uint8[] memory) {
        return skyRarities;
    }

    function geColorPaletteRarities() external view virtual override returns (uint8[] memory) {
        return trailPaletteRarities;
    }

    //------------------------------
    //owner only

    function setPalette(uint i, bytes3[] memory newColors) external virtual onlyOwner {
        palettes[i] = newColors;
    }

    function setPaletteName(uint i, string memory name) external virtual onlyOwner {
        trailPaletteNames[i] = name;
    }

    function setSkyPalette(uint i, bytes3[2] memory newColors) virtual external onlyOwner {
        skyCols[i] = newColors;
    }

    function setSkyName(uint i, string memory name) external virtual onlyOwner{
        skyColNames[i] = name;
    }
}