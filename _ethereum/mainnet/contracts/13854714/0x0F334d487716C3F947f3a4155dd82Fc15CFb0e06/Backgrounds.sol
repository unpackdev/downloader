//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Trait.sol";

contract Backgrounds is Trait {
  // Skin view
  string public constant FRONT_RED = "#e1c2bd";
  string public constant FRONT_PINK = "#f7c3e0";
  string public constant FRONT_ORANGE = "#f2d59c";
  string public constant FRONT_YELLOW = "#fdfad1";
  string public constant FRONT_GREEN = "#c8e6c1";
  string public constant FRONT_BLUE = "#c0ece9";
  string public constant FRONT_PURPLE = "#dbb9f0";
  string public constant FRONT_GRAY = "#c1c1a6";

  constructor() {
    _tiers = [1250, 2500, 3750, 5000, 6250, 7500, 8750, 10000];
  }

  function getName(uint256 traitIndex)
    public
    pure
    override
    returns (string memory name)
  {
    if (traitIndex == 0) {
      return "Red";
    } else if (traitIndex == 1) {
      return "Pink";
    } else if (traitIndex == 2) {
      return "Orange";
    } else if (traitIndex == 3) {
      return "Yellow";
    } else if (traitIndex == 4) {
      return "Green";
    } else if (traitIndex == 5) {
      return "Blue";
    } else if (traitIndex == 6) {
      return "Purple";
    } else if (traitIndex == 7) {
      return "Gray";
    }
  }

  function _getLayer(
    uint256 traitIndex,
    uint256,
    string memory prefix
  ) internal view override returns (string memory layer) {
    if (traitIndex == 0) {
      return _layer(prefix, "RED");
    } else if (traitIndex == 1) {
      return _layer(prefix, "PINK");
    } else if (traitIndex == 2) {
      return _layer(prefix, "ORANGE");
    } else if (traitIndex == 3) {
      return _layer(prefix, "YELLOW");
    } else if (traitIndex == 4) {
      return _layer(prefix, "GREEN");
    } else if (traitIndex == 5) {
      return _layer(prefix, "BLUE");
    } else if (traitIndex == 6) {
      return _layer(prefix, "PURPLE");
    } else if (traitIndex == 7) {
      return _layer(prefix, "GRAY");
    }
  }
}
