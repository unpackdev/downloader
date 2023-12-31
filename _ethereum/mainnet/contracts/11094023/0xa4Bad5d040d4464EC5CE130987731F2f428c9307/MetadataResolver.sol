pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./MushroomLib.sol";

abstract contract MetadataResolver {
    using MushroomLib for MushroomLib.MushroomData;
    using MushroomLib for MushroomLib.MushroomType;

    function getMushroomData(uint256 index, bytes calldata data) external virtual view returns (MushroomLib.MushroomData memory);
    function setMushroomLifespan(uint256 index, uint256 lifespan, bytes calldata data) external virtual;
}
