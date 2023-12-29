// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Types.sol";

interface IBeacon {
    function getParcelCode(
        uint256
    ) external view returns (AntennaStatus, string memory);

    function getParcelCodeFromPlacement(
        uint256
    ) external view returns (AntennaStatus, string memory);

    function scriptFonts(uint) external view returns (string memory);
    function scriptLibraries(uint) external view returns (string memory);
    function scriptBodies(uint) external view returns (string memory);
    function scriptLoopStarts(uint) external view returns (string memory);
    function scriptLoopEnds(uint) external view returns (string memory);
}
