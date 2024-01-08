//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//inspired by David Merfield's randomColor.js
//https://github.com/davidmerfield/randomColor

import "./Strings.sol";
import "./ColorStrings.sol";
import "./Randomize.sol";

abstract contract RandomColor {
  using Strings for uint256;
  using ColorStrings for uint256;
  using Randomize for Randomize.Random;

  struct HueRange {
    string _name;
    uint256 _min;
    uint256 _max;
  }

  struct Range {
    uint256 _min;
    uint256 _max;
  }

  struct LowerBound {
    uint256 _saturation;
    uint256 _brightness;
  }

  HueRange[] private _hueRanges;

  mapping(string => LowerBound[]) private _lowerBounds;
  mapping(string => Range) private _saturationRanges;
  mapping(string => Range) private _brightnessRanges;

  constructor() {
    _hueRangeSetup();
    _lowerBoundMapping();
    _saturationRangeMapping();
    _brightnessRangeMapping();
  }

  function _hueRangeSetup() private {
    _hueRanges.push(HueRange('red', 0, 18));
    _hueRanges.push(HueRange('orange', 18, 46));
    _hueRanges.push(HueRange('yellow', 46, 62));
    _hueRanges.push(HueRange('green', 62, 178));
    _hueRanges.push(HueRange('blue', 178, 257));
    _hueRanges.push(HueRange('purple', 257, 282));
    _hueRanges.push(HueRange('pink', 282, 334));
  }

  function _lowerBoundMapping() private {
    _lowerBounds['red'].push(LowerBound(20, 100));
    _lowerBounds['red'].push(LowerBound(30, 92));
    _lowerBounds['red'].push(LowerBound(40, 89));
    _lowerBounds['red'].push(LowerBound(50, 85));
    _lowerBounds['red'].push(LowerBound(60, 78));
    _lowerBounds['red'].push(LowerBound(70, 70));
    _lowerBounds['red'].push(LowerBound(80, 60));
    _lowerBounds['red'].push(LowerBound(90, 55));
    _lowerBounds['red'].push(LowerBound(100, 50));

    _lowerBounds['orange'].push(LowerBound(20, 100));
    _lowerBounds['orange'].push(LowerBound(30, 93));
    _lowerBounds['orange'].push(LowerBound(40, 88));
    _lowerBounds['orange'].push(LowerBound(50, 86));
    _lowerBounds['orange'].push(LowerBound(60, 85));
    _lowerBounds['orange'].push(LowerBound(70, 70));
    _lowerBounds['orange'].push(LowerBound(100, 70));

    _lowerBounds['yellow'].push(LowerBound(25, 100));
    _lowerBounds['yellow'].push(LowerBound(40, 94));
    _lowerBounds['yellow'].push(LowerBound(50, 89));
    _lowerBounds['yellow'].push(LowerBound(60, 86));
    _lowerBounds['yellow'].push(LowerBound(70, 84));
    _lowerBounds['yellow'].push(LowerBound(80, 82));
    _lowerBounds['yellow'].push(LowerBound(90, 80));
    _lowerBounds['yellow'].push(LowerBound(100, 75));

    _lowerBounds['green'].push(LowerBound(30, 100));
    _lowerBounds['green'].push(LowerBound(40, 90));
    _lowerBounds['green'].push(LowerBound(50, 85));
    _lowerBounds['green'].push(LowerBound(60, 81));
    _lowerBounds['green'].push(LowerBound(70, 74));
    _lowerBounds['green'].push(LowerBound(80, 64));
    _lowerBounds['green'].push(LowerBound(90, 50));
    _lowerBounds['green'].push(LowerBound(100, 40));

    _lowerBounds['blue'].push(LowerBound(20, 100));
    _lowerBounds['blue'].push(LowerBound(30, 86));
    _lowerBounds['blue'].push(LowerBound(40, 80));
    _lowerBounds['blue'].push(LowerBound(50, 74));
    _lowerBounds['blue'].push(LowerBound(60, 60));
    _lowerBounds['blue'].push(LowerBound(70, 52));
    _lowerBounds['blue'].push(LowerBound(80, 44));
    _lowerBounds['blue'].push(LowerBound(90, 39));
    _lowerBounds['blue'].push(LowerBound(100, 35));

    _lowerBounds['purple'].push(LowerBound(20, 100));
    _lowerBounds['purple'].push(LowerBound(30, 87));
    _lowerBounds['purple'].push(LowerBound(40, 79));
    _lowerBounds['purple'].push(LowerBound(50, 70));
    _lowerBounds['purple'].push(LowerBound(60, 65));
    _lowerBounds['purple'].push(LowerBound(70, 59));
    _lowerBounds['purple'].push(LowerBound(80, 52));
    _lowerBounds['purple'].push(LowerBound(90, 45));
    _lowerBounds['purple'].push(LowerBound(100, 42));

    _lowerBounds['pink'].push(LowerBound(20, 100));
    _lowerBounds['pink'].push(LowerBound(30, 90));
    _lowerBounds['pink'].push(LowerBound(40, 86));
    _lowerBounds['pink'].push(LowerBound(60, 84));
    _lowerBounds['pink'].push(LowerBound(80, 80));
    _lowerBounds['pink'].push(LowerBound(90, 75));
    _lowerBounds['pink'].push(LowerBound(100, 73));
  }

  function _saturationRangeMapping() private {
    _saturationRanges['red'] = Range(20, 100);
    _saturationRanges['orange'] = Range(20, 100);
    _saturationRanges['yellow'] = Range(25, 100);
    _saturationRanges['green'] = Range(30, 100);
    _saturationRanges['blue'] = Range(20, 100);
    _saturationRanges['purple'] = Range(20, 100);
    _saturationRanges['pink'] = Range(30, 100);
  }

  function _brightnessRangeMapping() private {
    _brightnessRanges['red'] = Range(50, 100);
    _brightnessRanges['orange'] = Range(70, 100);
    _brightnessRanges['yellow'] = Range(75, 100);
    _brightnessRanges['green'] = Range(40, 100);
    _brightnessRanges['blue'] = Range(35, 100);
    _brightnessRanges['purple'] = Range(42, 100);
    _brightnessRanges['pink'] = Range(73, 100);
  }

  function _pickHue(Randomize.Random memory random) private pure returns (uint256) {
    return random.next(0, 360);
  }

  function _pickSaturation(Randomize.Random memory random, uint256 hue)
    private
    view
    returns (uint256)
  {
    string memory colorName = _getColorName(hue);
    require(keccak256(bytes(colorName)) != keccak256(bytes('not_found')), 'Color name not found');

    Range memory saturationRange = _saturationRanges[colorName];
    return random.next(saturationRange._min, saturationRange._max);
  }

  function _pickBrightness(
    Randomize.Random memory random,
    uint256 hue,
    uint256 saturation
  ) private view returns (uint256) {
    string memory colorName = _getColorName(hue);
    require(keccak256(bytes(colorName)) != keccak256(bytes('not_found')), 'Color name not found');

    uint256 minBrightness = _getMinimumBrightness(hue, saturation);
    uint256 maxBrightness = 100;

    if (minBrightness == maxBrightness) {
      return minBrightness;
    }

    return random.next(minBrightness, maxBrightness);
  }

  function _getMinimumBrightness(uint256 hue, uint256 saturation) private view returns (uint256) {
    string memory colorName = _getColorName(hue);
    require(keccak256(bytes(colorName)) != keccak256(bytes('not_found')), 'Color name not found');

    LowerBound[] memory lowerBounds = _lowerBounds[colorName];
    uint256 len = lowerBounds.length;
    for (uint256 i = 0; i < len - 1; i++) {
      uint256 s1 = lowerBounds[i]._saturation;
      uint256 v1 = lowerBounds[i]._brightness;

      uint256 s2 = lowerBounds[i + 1]._saturation;
      uint256 v2 = lowerBounds[i + 1]._brightness;

      if (saturation >= s1 && saturation <= s2) {
        int256 m = ((int256(v2) - int256(v1)) * 10) / int256(s2 - s1);
        int256 b = int256(v1 * 10) - (m * int256(s1));

        return uint256((m * int256(saturation) + b) / 10);
      }
    }
    return 0;
  }

  function _getColorName(uint256 hue) private view returns (string memory) {
    if (hue >= 334 && hue <= 360) {
      hue = 0;
    }

    uint256 len = _hueRanges.length;
    for (uint256 i = 0; i < len; i++) {
      if (hue >= _hueRanges[i]._min && hue <= _hueRanges[i]._max) {
        return _hueRanges[i]._name;
      }
    }
    return 'not_found';
  }

  /// @dev this function is not accurate due to rounding errors, and may have an error of 1 for each value of rgb.
  function _hsvToRgb(
    uint256 hue,
    uint256 saturation,
    uint256 value
  ) private pure returns (uint256[3] memory) {
    if (hue == 0) {
      hue = 1;
    }
    if (hue == 360) {
      hue = 359;
    }

    uint256 multiplier = 10000;
    uint256 h = (hue * multiplier) / 360;
    uint256 s = (saturation * multiplier) / 100;
    uint256 v = (value * multiplier) / 100;

    uint256 h_i = (h * 6);
    uint256 f = h_i % multiplier;
    uint256 p = (v * (1 * multiplier - s)) / multiplier;
    uint256 q = (v * (1 * multiplier - ((f * s) / multiplier))) / multiplier;
    uint256 t = (v * (1 * multiplier - (((1 * multiplier - f) * s) / multiplier))) / multiplier;
    uint256 r = 256;
    uint256 g = 256;
    uint256 b = 256;

    if (h_i < 1 * multiplier) {
      r = v;
      g = t;
      b = p;
    } else if (h_i < 2 * multiplier) {
      r = q;
      g = v;
      b = p;
    } else if (h_i < 3 * multiplier) {
      r = p;
      g = v;
      b = t;
    } else if (h_i < 4 * multiplier) {
      r = p;
      g = q;
      b = v;
    } else if (h_i < 5 * multiplier) {
      r = t;
      g = p;
      b = v;
    } else if (h_i < 6 * multiplier) {
      r = v;
      g = p;
      b = q;
    }

    return [(r * 255) / multiplier, (g * 255) / multiplier, (b * 255) / multiplier];
  }

  function _rgbToHexString(uint256[3] memory rgb) private pure returns (string memory) {
    string memory colorCode = string(
      abi.encodePacked(
        '#',
        rgb[0].toHexColorString(),
        rgb[1].toHexColorString(),
        rgb[2].toHexColorString()
      )
    );
    return colorCode;
  }

  function _getColorCode(uint256 seed) internal view returns (string memory) {
    Randomize.Random memory random = Randomize.Random({seed: seed, offsetBit: 0});
    uint256 hue = _pickHue(random);
    uint256 saturation = _pickSaturation(random, hue);
    uint256 brightness = _pickBrightness(random, hue, saturation);

    uint256[3] memory rgb = _hsvToRgb(hue, saturation, brightness);

    return _rgbToHexString(rgb);
  }

  function _getColorCode(
    uint256 hue,
    uint256 saturation,
    uint256 brightness
  ) internal pure returns (string memory) {
    require(hue <= 360, 'Max hue is 360');
    require(saturation <= 100, 'Max saturation is 100');
    require(brightness <= 100, 'Max brightness is 100');

    uint256[3] memory rgb = _hsvToRgb(hue, saturation, brightness);
    return _rgbToHexString(rgb);
  }
}
