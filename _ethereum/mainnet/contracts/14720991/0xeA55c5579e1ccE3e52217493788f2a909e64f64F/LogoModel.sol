//	SPDX-License-Identifier: MIT
/// @notice Definition of Logo model
pragma solidity ^0.8.0;

library Model {

  /// @notice A logo container which holds layers of composable visual onchain assets
  struct Logo {
    uint16 width;
    uint16 height;
    LogoElement[] layers;
    LogoElement text;
  }

  /// @notice A layer of a logo displaying a visual onchain asset
  struct LogoElement {
    address contractAddress;
    uint32 tokenId;
    uint8 translateXDirection;
    uint16 translateX;
    uint8 translateYDirection;
    uint16 translateY;
    uint8 scaleDirection;
    uint8 scaleMagnitude;
  }

  /// @notice Data that can be set by logo owners and can be used in a composable onchain manner
  struct MetaData {
    string key;
    string value;
  }
}