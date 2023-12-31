// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

// restriction: uint<n> n needs to be different for each type to support function overloading
type VersionPart is uint16;
type Version is uint48; // to concatenate major,minor,patch version parts

using {
    gtVersion as >,
    gteVersion as >=,
    eqVersion as ==
}
    for Version global;

function gtVersion(Version a, Version b) pure returns(bool isGreaterThan) { return Version.unwrap(a) > Version.unwrap(b); }
function gteVersion(Version a, Version b) pure returns(bool isGreaterOrSame) { return Version.unwrap(a) >= Version.unwrap(b); }
function eqVersion(Version a, Version b) pure returns(bool isSame) { return Version.unwrap(a) == Version.unwrap(b); }

function versionPartToInt(VersionPart x) pure returns(uint) { return VersionPart.unwrap(x); }
function versionToInt(Version x) pure returns(uint) { return Version.unwrap(x); }

function toVersionPart(uint16 versionPart) pure returns(VersionPart) { return VersionPart.wrap(versionPart); }

function toVersion(
    VersionPart major,
    VersionPart minor,
    VersionPart patch
)
    pure
    returns(Version)
{
    uint majorInt = versionPartToInt(major);
    uint minorInt = versionPartToInt(minor);
    uint patchInt = versionPartToInt(patch);

    return Version.wrap(
        uint48(
            (majorInt << 32) + (minorInt << 16) + patchInt));
}


function zeroVersion() pure returns(Version) {
    return toVersion(toVersionPart(0), toVersionPart(0), toVersionPart(0));
}


// function toVersionParts(Version _version)
//     pure
//     returns(
//         VersionPart major,
//         VersionPart minor,
//         VersionPart patch
//     )
// {
//     uint versionInt = versionToInt(_version);
//     uint16 majorInt = uint16(versionInt >> 32);

//     versionInt -= majorInt << 32;
//     uint16 minorInt = uint16(versionInt >> 16);
//     uint16 patchInt = uint16(versionInt - (minorInt << 16));

//     return (
//         toVersionPart(majorInt),
//         toVersionPart(minorInt),
//         toVersionPart(patchInt)
//     );
// }
