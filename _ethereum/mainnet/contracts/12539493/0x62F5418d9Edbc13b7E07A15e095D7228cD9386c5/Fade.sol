// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fade by Pak
/// @author: manifold.xyz

//////////////////////////////////////////
//                                      //
//    ██████  ▓▓▓▓▓▓  ▒▒▒▒    ░░░░░░    //
//    ██      ▓▓  ▓▓  ▒▒  ▒▒  ░░        //
//    ████    ▓▓▓▓▓▓  ▒▒  ▒▒  ░░░░      //
//    ██      ▓▓  ▓▓  ▒▒  ▒▒  ░░        //
//    ██      ▓▓  ▓▓  ▒▒▒▒    ░░░░░░    //
//                                      //
//////////////////////////////////////////

import "./Ownable.sol";
import "./ERC721.sol";
import "./Strings.sol";
import "./ABDKMath64x64.sol";


contract Fade is ERC721, Ownable {

    using Strings for uint256;
    using ABDKMath64x64 for int128;

    uint256 private _creationTimestamp;
    uint256 private _completionTimestamp;

    string constant private _RADIUS_TAG = '<RADIUS>';
    string constant private _HUE1_TAG = '<HUE1>';
    string constant private _SATURATION1_TAG = '<SATURATION1>';
    string constant private _LIGHTNESS1_TAG = '<LIGHTNESS1>';
    string constant private _HUE2_TAG = '<HUE2>';
    string constant private _SATURATION2_TAG = '<SATURATION2>';
    string constant private _LIGHTNESS2_TAG = '<LIGHTNESS2>';

    string[] private _imageParts;


    constructor() ERC721("Fade", "FADE") {
        _imageParts.push("data:image/svg+xml;utf8,");
        _imageParts.push("<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' id='fade' width='1000' height='1000' viewBox='-0.5 -0.5 1 1'>");
            _imageParts.push("<defs><linearGradient id='g' x1='0' x2='0' y1='0' y2='1'><stop offset='0%' stop-color='hsl(");
                _imageParts.push(_HUE1_TAG);
                _imageParts.push(",");
                _imageParts.push(_SATURATION1_TAG);
                _imageParts.push("%,");
                _imageParts.push(_LIGHTNESS1_TAG);
                _imageParts.push("%)' /><stop offset='50%' stop-color='hsl(");
                _imageParts.push(_HUE2_TAG);
                _imageParts.push(",");
                _imageParts.push(_SATURATION2_TAG);
                _imageParts.push("%,");
                _imageParts.push(_LIGHTNESS2_TAG);
            _imageParts.push("%)' /><stop offset='100%' stop-color='hsl(0,0%,15%)' /></linearGradient></defs>");
            _imageParts.push("<g><rect x='-0.5' y='-0.5' width='1' height='1' fill='hsl(0,0%,15%)' /><circle cx='0' cy='0' r='");
                _imageParts.push(_RADIUS_TAG);
            _imageParts.push("' fill='url(#g)'><animateTransform attributeName='transform' type='rotate' from='0' to='360' dur='60s' repeatCount='indefinite' /></circle></g>");
        _imageParts.push("</svg>");
        _mint(msg.sender, 1);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        int128 completion = 1;
        if (_completionTimestamp > block.timestamp) {
            completion = ABDKMath64x64.divu(_completionTimestamp-block.timestamp, 31536000);
        }
        int128 distance = completion.pow(3).mul(ABDKMath64x64.div(48, 100)).add(ABDKMath64x64.div(2, 100))+1;

        //x^y = 2^(y*log_2(x))
        int128 c1curve = ABDKMath64x64.exp_2(ABDKMath64x64.div(75,100).mul(ABDKMath64x64.log_2(completion)));
        int128 c2curve = ABDKMath64x64.exp_2(ABDKMath64x64.div(125,100).mul(ABDKMath64x64.log_2(completion)));
        int128 w1value = ABDKMath64x64.fromUInt(uint256(uint160(ownerOf(tokenId)) & 0xFF)).div(ABDKMath64x64.fromUInt(255));
        int128 w2value = ABDKMath64x64.fromUInt(uint256((uint160(ownerOf(tokenId)) >> 8) & 0xFF)).div(ABDKMath64x64.fromUInt(255));

        int128 randHue = ABDKMath64x64.mul(w1value, ABDKMath64x64.fromUInt(360));
        int128 randOffset = ABDKMath64x64.mul(w2value, ABDKMath64x64.fromUInt(180)).add(ABDKMath64x64.fromUInt(360)).sub(ABDKMath64x64.fromUInt(90));

        return string(abi.encodePacked('data:application/json;utf8,{"name":"Fade", "description":"TEMPUS EDAX RERUM\\n',((block.timestamp-_creationTimestamp)/86400).toString(),'", "created_by":"Pak", "image":"',
            _generateImage(distance, completion, c1curve, c2curve, randHue, randOffset),
            '"}'));
    }

    function updateImageParts(string[] memory imageParts) public onlyOwner {
        _imageParts = imageParts;
    }

    function _generateImage(int128 distance, int128 completion, int128 c1curve, int128 c2curve, int128 randHue, int128 randOffset) private view returns (string memory radius) {
        bytes memory byteString;
        for (uint i = 0; i < _imageParts.length; i++) {
            if (_checkTag(_imageParts[i], _RADIUS_TAG)) {
                byteString = abi.encodePacked(byteString, _radiusString(distance));
            } else if (_checkTag(_imageParts[i], _HUE1_TAG)) {
                byteString = abi.encodePacked(byteString, _hue1string(completion, randHue));
            } else if (_checkTag(_imageParts[i], _SATURATION1_TAG)) {
                byteString = abi.encodePacked(byteString, _saturation1String(c1curve));
            } else if (_checkTag(_imageParts[i], _LIGHTNESS1_TAG)) {
                byteString = abi.encodePacked(byteString, _lightness1String(c1curve));
            } else if (_checkTag(_imageParts[i], _HUE2_TAG)) {
                byteString = abi.encodePacked(byteString, _hue2string(completion, randHue, randOffset));
            } else if (_checkTag(_imageParts[i], _SATURATION2_TAG)) {
                byteString = abi.encodePacked(byteString, _saturation2String(c2curve));
            } else if (_checkTag(_imageParts[i], _LIGHTNESS2_TAG)) {
                byteString = abi.encodePacked(byteString, _lightness2String(c2curve));
            } else {
                byteString = abi.encodePacked(byteString, _imageParts[i]);
            }
        }
        return string(byteString);
    }

    function _checkTag(string storage a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function _radiusString(int128 distance) private pure returns (string memory) {
        return _floatToString(distance);
    }

    function _hue1string(int128 completion, int128 randHue) private pure returns (string memory) {
        int128 hueValue = randHue.add(completion.mul(ABDKMath64x64.fromUInt(60)));
        uint256 decimal4 = (hueValue & 0xFFFFFFFFFFFFFFFF).mulu(10000);
        return string(abi.encodePacked(_toString(hueValue.toInt() % 360), '.', _decimal4ToString(decimal4)));
    }

    function _saturation1String(int128 c1curve) private pure returns (string memory) {
        return _floatToString(c1curve.mul(ABDKMath64x64.fromUInt(100)));
    }

    function _lightness1String(int128 c1curve) private pure returns (string memory) {
        return _floatToString(c1curve.mul(ABDKMath64x64.fromUInt(70))+ABDKMath64x64.fromUInt(15));
    }

    function _hue2string(int128 completion, int128 randHue, int128 randOffset) private pure returns (string memory) {
        int128 hueValue = randHue.add(completion.mul(ABDKMath64x64.fromUInt(60)).add(randOffset));
        uint256 decimal4 = (hueValue & 0xFFFFFFFFFFFFFFFF).mulu(10000);
        return string(abi.encodePacked(_toString(hueValue.toInt() % 360), '.', _decimal4ToString(decimal4)));
    }

    function _saturation2String(int128 c2curve) private pure returns (string memory) {
        return _floatToString(c2curve.mul(ABDKMath64x64.fromUInt(50)));
    }

    function _lightness2String(int128 c2curve) private pure returns (string memory) {
        return _floatToString(c2curve.mul(ABDKMath64x64.fromUInt(35))+ABDKMath64x64.fromUInt(15));
    }

    function _toString(int128 value) private pure returns (string memory) {
        return uint256(int256(value)).toString();
    }

    function _floatToString(int128 value) private pure returns (string memory) {
        uint256 decimal4 = (value & 0xFFFFFFFFFFFFFFFF).mulu(10000);
        return string(abi.encodePacked(uint256(int256(value.toInt())).toString(), '.', _decimal4ToString(decimal4)));
    }

    function _decimal4ToString(uint256 decimal4) private pure returns (string memory) {
        bytes memory decimal4Characters = new bytes(4);
        for (uint i = 0; i < 4; i++) {
            decimal4Characters[3 - i] = bytes1(uint8(0x30 + decimal4 % 10));
            decimal4 /= 10;
        }
        return string(abi.encodePacked(decimal4Characters));
    }
    
    function _beforeTokenTransfer(address, address, uint256) internal virtual override {
        _creationTimestamp = block.timestamp;
        _completionTimestamp = block.timestamp+31536000;
    }
}
