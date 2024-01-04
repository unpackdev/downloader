// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IOVRLand {
    function mintLand(address to, uint256 OVRLandID) external returns (bool);

    function setOVRLandURI(uint256 OVRLandID, string memory uri) external;
}
