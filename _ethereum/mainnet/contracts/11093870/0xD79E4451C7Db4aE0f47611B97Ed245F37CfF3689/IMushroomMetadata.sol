pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./MushroomLib.sol";

abstract contract IMushroomMetadata {
    using MushroomLib for MushroomLib.MushroomData;
    using MushroomLib for MushroomLib.MushroomType;

    function hasMetadataResolver(address nftContract) external virtual view returns (bool);

    function getMushroomData(
        address nftContract,
        uint256 nftIndex,
        bytes calldata data
    ) external virtual view returns (MushroomLib.MushroomData memory);

    function setMushroomLifespan(
        address nftContract,
        uint256 nftIndex,
        uint256 lifespan,
        bytes calldata data
    ) external virtual;

    function setResolver(address nftContract, address resolver) public virtual;
}
