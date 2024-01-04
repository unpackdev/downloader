// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

interface IKeep3rV1 {

    function isKeeper(address) external returns (bool);

    function worked(address keeper) external;

    function bond(address bonding, uint amount) external;

    function activate(address bonding) external;
}
