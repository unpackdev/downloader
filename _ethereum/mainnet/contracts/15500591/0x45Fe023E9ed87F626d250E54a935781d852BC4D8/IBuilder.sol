// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./IPixelRenderer.sol";
import "./IAnimationEncoder.sol";
import "./ISVGWrapper.sol";

interface IBuilder {
    function getCanonicalSize() external view returns (uint width, uint height);
    function getImage(IPixelRenderer renderer, IAnimationEncoder encoder, uint8[] memory metadata, uint tokenId) external view returns (string memory);
}