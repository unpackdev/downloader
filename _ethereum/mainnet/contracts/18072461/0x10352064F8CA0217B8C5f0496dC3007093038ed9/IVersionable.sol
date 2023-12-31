// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {Blocknumber, Timestamp} from "IBaseTypes.sol";
import {Version, VersionPart} from "IVersionType.sol";

interface IVersionable {

    struct VersionInfo {
        Version version;
        address implementation;
        address activatedBy;
        Blocknumber activatedIn;
        Timestamp activatedAt;
    }

    event LogVersionableActivated(Version version, address implementation, address activatedBy);

    /**
     * @dev IMPORTANT this function needs to be implemented by each new version
     * any such activate implementation needs to call internal function call _activate() 
     * any new version needs to inherit from previous version
     */
    function activate(address implementation, address activatedBy) external;
    function isActivated(Version _version) external view returns(bool);

    function toVersionParts(Version _version)
        external
        pure
        returns(
            VersionPart major,
            VersionPart minor,
            VersionPart patch
        );
    
    // returns current version (ideally immutable)
    function version() external pure returns(Version);
    function versionParts()
        external
        pure
        returns(
            VersionPart major,
            VersionPart minor,
            VersionPart patch
        );

    function versions() external view returns(uint256);
    function getVersion(uint256 idx) external view returns(Version);
    function getVersionInfo(Version _version) external view returns(VersionInfo memory);
}