pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";
import "./Ownable.sol";
import "./MetadataResolver.sol";
import "./MushroomLib.sol";

contract MushroomMetadata is Ownable {
    using MushroomLib for MushroomLib.MushroomData;
    using MushroomLib for MushroomLib.MushroomType;

    mapping(address => address) public metadataResolvers;

    event ResolverSet(address nft, address resolver);

    modifier onlyWithMetadataResolver(address nftContract) {
        require(metadataResolvers[nftContract] != address(0), "MetadataRegistry: No resolver set for nft");
        _;
    }

    function hasMetadataResolver(address nftContract) external view returns (bool) {
        return metadataResolvers[nftContract] != address(0);
    }

    function getMushroomData(
        address nftContract,
        uint256 nftIndex,
        bytes calldata data
    ) external view onlyWithMetadataResolver(nftContract) returns (MushroomLib.MushroomData memory) {
        MetadataResolver resolver = MetadataResolver(metadataResolvers[nftContract]);
        MushroomLib.MushroomData memory mushroomData = resolver.getMushroomData(nftIndex, data);
        return mushroomData;
    }

    function setMushroomLifespan(
        address nftContract,
        uint256 nftIndex,
        uint256 lifespan,
        bytes calldata data
    ) external onlyWithMetadataResolver(nftContract) {
        MetadataResolver resolver = MetadataResolver(metadataResolvers[nftContract]);
        resolver.setMushroomLifespan(nftIndex, lifespan, data);
    }

    function setResolver(address nftContract, address resolver) public onlyOwner {
        metadataResolvers[nftContract] = resolver;

        emit ResolverSet(nftContract, resolver);
    }
}
