// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Structs.sol";
import "./IArtData.sol";

interface IPlaneFactory {
    function buildPlane(string memory seed, uint256 planeInstId, IArtData artData, uint numTrailColors) external view returns (PlaneAttributes memory);
}
