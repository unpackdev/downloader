// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

/// @title Genesis Group interface
/// @author Ring Protocol
interface IGenesisGroup {
    // ----------- Events -----------

    event Launch(uint256 _timestamp);

    // ----------- State changing API -----------

    function launch() external;

    // ----------- Getters -----------

    function launchBlock() external view returns (uint256);
}
