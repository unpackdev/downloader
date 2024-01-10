// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./MaviaNFT.sol";

/**
 * @title Mavia NFT Hero
 *
 * @notice This contract contains base implementation of Mavia NFT Hero
 *
 * @dev This contract is inherited from MaviaNFT
 *
 * @author mavia.com, reviewed by King
 *
 * Copyright (c) 2021 Mavia
 */
contract MaviaNFTHero is MaviaNFT {
  /**
   * @dev Upgradable initializer
   * @param _pUri URI string
   */
  function __MaviaNFTHero_init(string memory _pUri) external initializer {
    __MaviaNFT_init("Mavia Heroes", "HERO", _pUri);
  }
}
