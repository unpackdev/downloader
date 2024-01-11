// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./ProxiedInternals.sol";

/// @title A Maple implementation that is to be proxied, will need MapleProxiedInternals.
abstract contract MapleProxiedInternals is ProxiedInternals {}
