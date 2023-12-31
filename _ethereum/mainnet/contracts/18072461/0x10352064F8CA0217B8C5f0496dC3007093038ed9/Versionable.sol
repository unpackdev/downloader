// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {Blocknumber, Timestamp, blockTimestamp} from "IBaseTypes.sol";
import {BaseTypes} from "BaseTypes.sol";
import {Version, VersionPart, toVersionPart, versionToInt, zeroVersion} from "IVersionType.sol";
import {IVersionable} from "IVersionable.sol";

contract Versionable is 
    BaseTypes,
    IVersionable
{

    mapping(Version version => VersionInfo info) private _versionHistory;
    Version [] private _versions;


    // controlled activation for controller contract
    constructor() {
        _activate(address(this), msg.sender);
    }

    // IMPORTANT this function needs to be implemented by each new version
    // and needs to call internal function call _activate() 
    function activate(address implementation, address activatedBy)
        external 
        virtual override
    { 
        _activate(implementation, activatedBy);
    }


    // can only be called once per contract
    // needs bo be called inside the proxy upgrade tx
    function _activate(
        address implementation,
        address activatedBy
    )
        internal
    {
        Version thisVersion = version();

        require(
            !isActivated(thisVersion),
            "ERROR:VRN-001:VERSION_ALREADY_ACTIVATED"
        );
        
        // require increasing version number
        if(_versions.length > 0) {
            Version lastVersion = _versions[_versions.length - 1];
            require(
                thisVersion > lastVersion,
                "ERROR:VRN-002:VERSION_NOT_INCREASING"
            );
        }

        // update version history
        _versions.push(thisVersion);
        _versionHistory[thisVersion] = VersionInfo(
            thisVersion,
            implementation,
            activatedBy,
            blockNumber(),
            blockTimestamp()
        );

        emit LogVersionableActivated(thisVersion, implementation, activatedBy);
    }


    function isActivated(Version _version) public override view returns(bool) {
        return toInt(_versionHistory[_version].activatedIn) > 0;
    }

    function toVersionParts(Version _version)
        public
        virtual
        pure
        returns(
            VersionPart major,
            VersionPart minor,
            VersionPart patch
        )
    {
        uint versionInt = versionToInt(_version);
        uint16 majorInt = uint16(versionInt >> 32);

        versionInt -= majorInt << 32;
        uint16 minorInt = uint16(versionInt >> 16);
        uint16 patchInt = uint16(versionInt - (minorInt << 16));

        return (
            toVersionPart(majorInt),
            toVersionPart(minorInt),
            toVersionPart(patchInt)
        );
    }


    // returns current version (ideally immutable)
    function version() public virtual override pure returns(Version) {
        return zeroVersion();
    }


    function versionParts()
        external
        override 
        pure
        returns(
            VersionPart major,
            VersionPart minor,
            VersionPart patch
        )
    {
        return toVersionParts(version());
    }


    function versions() external view returns(uint256) {
        return _versions.length;
    }


    function getVersion(uint256 idx) external override view returns(Version) {
        require(idx < _versions.length, "ERROR:VRN-010:INDEX_TOO_LARGE");
        return _versions[idx];
    }


    function getVersionInfo(Version _version) external override view returns(VersionInfo memory) {
        require(isActivated(_version), "ERROR:VRN-020:VERSION_UNKNOWN");
        return _versionHistory[_version];
    }
}