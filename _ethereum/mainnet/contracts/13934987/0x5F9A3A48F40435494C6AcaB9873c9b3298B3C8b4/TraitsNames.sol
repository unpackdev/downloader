// contracts/libs/Traits.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

library TraitsNames {
  function _color(uint8 id) internal pure returns (string memory) {
    if (id == 0) {
      return "Pink";
    } else if (id == 1) {
      return "Gold";
    } else if (id == 2) {
      return "Green";
    } else if (id == 3) {
      return "Light Blue";
    } else if (id == 4) {
      return "Earth";
    } else if (id == 5) {
      return "Red";
    } else if (id == 6) {
      return "Cotton Candy";
    } else if (id == 7) {
      return "Space Black";
    } else if (id == 8) {
      return "Terra";
    } else if (id == 9) {
      return "Sunset Cloud";
    } else if (id == 10) {
      return "Lavender";
    } else if (id == 11) {
      return "Peach";
    } else if (id == 12) {
      return "Blue";
    } else {
      require(true, "Bad id");
    }

    return "";
  }

  function headgear(uint8 id) internal pure returns (string memory) {
    if (id == 0) {
      return "No Headgear";
    } else if (id == 1) {
      return "Aero Cap";
    } else if (id == 2) {
      return "Guardian Helmet";
    } else if (id == 3) {
      return "Headphones Helmet";
    } else if (id == 4) {
      return "Crown";
    } else if (id == 5) {
      return "Winged Headphones";
    } else {
      require(true, "Bad id");
    }

    return "";
  }

  function faceMask(uint8 id) internal pure returns (string memory) {
    if (id == 0) {
      return "No Facemask";
    } else if (id == 1) {
      return "Purifier";
    } else {
      require(true, "Bad id");
    }

    return "";
  }

  function eye(uint8 id) internal pure returns (string memory) {
    if (id == 0) {
      return "Happy";
    } else if (id == 1) {
      return "Rolling";
    } else if (id == 2) {
      return "Crushing";
    } else if (id == 3) {
      return "Sad";
    } else {
      require(true, "Bad id");
    }

    return "";
  }

  function cornea(uint8 id) internal pure returns (string memory) {
    return _color(id);
  }

  function pupil(uint8 id) internal pure returns (string memory) {
    return _color(id);
  }

  function footwear(uint8 id) internal pure returns (string memory) {
    if (id == 0) {
      return "No boots";
    } else if (id == 1) {
      return "Tech Boots";
    } else if (id == 2) {
      return "Terra Boots";
    } else if (id == 3) {
      return "Aero Boots";
    } else if (id == 4) {
      return "Guardian Boots";
    } else if (id == 5) {
      return "Cozy Slides";
    } else if (id == 6) {
      return "Sprinter Sneaker";
    } else {
      require(true, "Bad id");
    }

    return "";
  }

  function clothing(uint8 id) internal pure returns (string memory) {
    if (id == 0) {
      return "Birthday Suit";
    } else if (id == 1) {
      return "Vest";
    } else if (id == 2) {
      return "Turtle";
    } else if (id == 3) {
      return "Buttons";
    } else if (id == 4) {
      return "Kimono";
    } else if (id == 5) {
      return "Sweater";
    } else if (id == 6) {
      return "Apron";
    } else {
      require(true, "Bad id");
    }

    return "";
  }

  function background(uint8 id) internal pure returns (string memory) {
    if (id == 0) {
      return "Solar";
    } else if (id == 1) {
      return "Flare 2";
    } else if (id == 2) {
      return "Flare 1";
    } else if (id == 3) {
      return "Saturn";
    } else if (id == 4) {
      return "Neptune";
    } else if (id == 5) {
      return "Mars";
    } else if (id == 6) {
      return "Flare 3";
    } else if (id == 7) {
      return "Flare 5";
    } else if (id == 8) {
      return "Prarie";
    } else if (id == 9) {
      return "Hill";
    } else if (id == 10) {
      return "Strada Orb";
    } else if (id == 11) {
      return "Canyon";
    } else {
      require(true, "Bad id");
    }

    return "";
  }

  function skinColor(uint8 id) internal pure returns (string memory) {
    return _color(id);
  }
}
