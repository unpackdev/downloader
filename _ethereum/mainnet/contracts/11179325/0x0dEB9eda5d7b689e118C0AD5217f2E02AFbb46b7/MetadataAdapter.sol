// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./MushroomLib.sol";
import "./AccessControl.sol";

/*
    Reads mushroom NFT metadata for a given NFT contract
    Also forwards requests from the MetadataResolver to set lifespan
*/
abstract contract MetadataAdapter is AccessControlUpgradeSafe {
    using MushroomLib for MushroomLib.MushroomData;
    using MushroomLib for MushroomLib.MushroomType;

    bytes32 public constant LIFESPAN_MODIFY_REQUEST_ROLE = keccak256("LIFESPAN_MODIFY_REQUEST_ROLE");

    modifier onlyLifespanModifier() {
        require(hasRole(LIFESPAN_MODIFY_REQUEST_ROLE, msg.sender), "onlyLifespanModifier");
        _;
    }

    function getMushroomData(uint256 index, bytes calldata data) external virtual view returns (MushroomLib.MushroomData memory);
    function setMushroomLifespan(uint256 index, uint256 lifespan, bytes calldata data) external virtual;
    function isBurnable(uint256 index) external view virtual returns (bool);
    function isStakeable(uint256 index) external view virtual returns (bool);
}
