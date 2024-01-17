// SPDX-License-Identifier: Commons-Clause-1.0
//                      _   _
//    /\/\   __ _ _ __ | |_| | ___
//   /    \ / _` | '_ \| __| |/ _ \
//  / /\/\ \ (_| | | | | |_| |  __/
//  \/    \/\__,_|_| |_|\__|_|\___|
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://mantle.gg

pragma solidity ^0.8.16;

contract Roles {
  bytes32 internal constant MINTER_ROLE = keccak256("METAFAB_MINTER_ROLE");
  bytes32 internal constant OWNER_ROLE = keccak256("METAFAB_OWNER_ROLE");
}
