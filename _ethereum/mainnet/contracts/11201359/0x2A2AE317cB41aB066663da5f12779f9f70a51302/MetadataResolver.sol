// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";
import "./AccessControl.sol";

import "./MetadataAdapter.sol";
import "./MushroomLib.sol";

/*
    A hub of adapters managing lifespan metadata for arbitrary NFTs
    Each adapter has it's own custom logic for that NFT
    Lifespan modification requesters have rights to manage lifespan metadata of NFTs via the adapters
    Admin(s) can manage the set of resolvers
*/
contract MetadataResolver is AccessControlUpgradeSafe {
    using MushroomLib for MushroomLib.MushroomData;
    using MushroomLib for MushroomLib.MushroomType;

    mapping(address => address) public metadataAdapters;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "onlyAdmin");
        _;
    }

    modifier onlyLifespanModifier() {
        require(hasRole(LIFESPAN_MODIFY_REQUEST_ROLE, msg.sender), "onlyLifespanModifier");
        _;
    }

    bytes32 public constant LIFESPAN_MODIFY_REQUEST_ROLE = keccak256("LIFESPAN_MODIFY_REQUEST_ROLE");

    event ResolverSet(address nft, address resolver);

    modifier onlyWithMetadataAdapter(address nftContract) {
        require(metadataAdapters[nftContract] != address(0), "MetadataRegistry: No resolver set for nft");
        _;
    }

    function hasMetadataAdapter(address nftContract) external view returns (bool) {
        return metadataAdapters[nftContract] != address(0);
    }

    function getMetadataAdapter(address nftContract) external view returns (address) {
        return metadataAdapters[nftContract];
    }

    function isStakeable(address nftContract, uint256 nftIndex) external view returns (bool) {
        if (metadataAdapters[nftContract] == address(0)) {
            return false;
        }
        
        MetadataAdapter resolver = MetadataAdapter(metadataAdapters[nftContract]);
        return resolver.isStakeable(nftIndex);
    }

    function initialize(address initialLifespanModifier_) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(LIFESPAN_MODIFY_REQUEST_ROLE, initialLifespanModifier_);
    }

    function getMushroomData(
        address nftContract,
        uint256 nftIndex,
        bytes calldata data
    ) external view onlyWithMetadataAdapter(nftContract) returns (MushroomLib.MushroomData memory) {
        MetadataAdapter resolver = MetadataAdapter(metadataAdapters[nftContract]);
        MushroomLib.MushroomData memory mushroomData = resolver.getMushroomData(nftIndex, data);
        return mushroomData;
    }

    function isBurnable(address nftContract, uint256 nftIndex) external view onlyWithMetadataAdapter(nftContract) returns (bool) {
        MetadataAdapter resolver = MetadataAdapter(metadataAdapters[nftContract]);
        return resolver.isBurnable(nftIndex);
    }

    function setMushroomLifespan(
        address nftContract,
        uint256 nftIndex,
        uint256 lifespan,
        bytes calldata data
    ) external onlyWithMetadataAdapter(nftContract) onlyLifespanModifier {
        MetadataAdapter resolver = MetadataAdapter(metadataAdapters[nftContract]);
        resolver.setMushroomLifespan(nftIndex, lifespan, data);
    }

    function setResolver(address nftContract, address resolver) public onlyAdmin {
        metadataAdapters[nftContract] = resolver;

        emit ResolverSet(nftContract, resolver);
    }
}
