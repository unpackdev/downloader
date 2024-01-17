// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import "./IOwnable.sol";

import "./ISimpleInitializable.sol";

import "./IAccountWhitelist.sol";

// solhint-disable-next-line no-empty-blocks
interface IOwnableAccountWhitelist is IAccountWhitelist, IOwnable, ISimpleInitializable {

}
