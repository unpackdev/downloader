// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./SoftStakingUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./ERC20PresetMinterPauserUpgradeable.sol";

contract FoothulkStaking is SoftStakingUpgradeable {
  function initializeV2(IERC721Upgradeable _nft) public initializer {
    __SoftStaking_init(
      _nft,
      "FHP",
      "FHP",
      5 ether,
      1 days,
      1667558978,
      6666600 ether
    );
  }
}
