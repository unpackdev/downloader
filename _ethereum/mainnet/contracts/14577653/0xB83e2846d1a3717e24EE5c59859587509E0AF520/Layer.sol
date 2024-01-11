// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

/**
 * A very basic layer contract that's initialized with different version of a layer
 * and then serves a layer based on an index.
 */
contract Layer {
    string[] private _layers;

    constructor(string[] memory layers) {
        _layers = layers;
    }

    function getLayerCount() external view returns (uint256 length) {
        return _layers.length;
    }

    function getLayer(uint256 index) external view returns (string memory) {
        return _layers[index];
    }
}
