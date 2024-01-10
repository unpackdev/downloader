// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./MaviaNFT.sol";
import "./MaviaNFT.sol";

/**
 * @title Mavia NFT Land
 *
 * @notice This contract contains base implementation of Mavia NFT Land
 *
 * @dev This contract is inherited from MaviaNFT
 *
 * @author mavia.com, reviewed by King
 *
 * Copyright (c) 2021 Mavia
 */
contract MaviaNFTLand is MaviaNFT {
  /**
   * @dev Upgradable initializer
   * @param _pUri URI string
   */
  function __MaviaNFTLand_init(string memory _pUri) external initializer {
    __MaviaNFT_init("Mavia Land", "LAND", _pUri);
  }
}
