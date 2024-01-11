// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Multicall.sol";

library GameFi {
  struct Hero {
    bytes32 name; // this is considered as hero's unique id in the ecosystem
    uint256 level;
    uint256 rarity;
    uint256 primaryAttribute; // 0: strength, 1: agility, 2: intelligence
    uint256 attackCapability; // 1: meleee, 2: ranged
    uint256 strength;
    uint256 strengthGain;
    uint256 agility;
    uint256 agilityGain;
    uint256 intelligence;
    uint256 intelligenceGain;
    uint256 experience; // (0 - 100) * 10**18
  }
}
