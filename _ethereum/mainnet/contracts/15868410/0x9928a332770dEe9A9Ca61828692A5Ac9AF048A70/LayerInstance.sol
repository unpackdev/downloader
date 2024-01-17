// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Layer.sol";

contract LayerInstance is Layer {
  constructor(
    string memory _layerName,
    address _composableNFTAddress,
    bool _isDefaultLayer
  ) {
    composableNFTAddress = _composableNFTAddress;
    isDefaultLayer = _isDefaultLayer;

    layerName = _layerName;
  }
}