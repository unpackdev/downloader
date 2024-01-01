// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./NativeOFTWithFeeUpgradeable.sol";
import "./ProxyOFTWithFeeUpgradeable.sol";

contract BeamProxyOFT is ProxyOFTWithFeeUpgradeable {}

contract BeamNativeOFT is NativeOFTWithFeeUpgradeable {}
