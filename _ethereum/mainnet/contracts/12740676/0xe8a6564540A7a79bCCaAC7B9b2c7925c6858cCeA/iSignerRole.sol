// SPDX-License-Identifier: MIT
// this is copied from MintableOwnableToken
// https://etherscan.io/address/0x987a4d3edbe363bc351771bb8abdf2a332a19131#code
// modified by TART-tokyo

pragma solidity =0.8.6;

interface iSignerRole {
    function isSigner(address account) external view returns (bool);
}
