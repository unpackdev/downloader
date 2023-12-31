pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";
import "./Ownable.sol";

import "./MushroomNFT.sol";
import "./MushroomLib.sol";
import "./MetadataResolver.sol";


/*
    Reads mushroom NFT metadata directly from the Mushroom NFT contract
*/ 
contract MushroomResolver is Initializable, OwnableUpgradeSafe, MetadataResolver {
    using MushroomLib for MushroomLib.MushroomData;
    using MushroomLib for MushroomLib.MushroomType;

    MushroomNFT public mushroomNft;

    function initialize(address mushroomNft_) public initializer {
        __Ownable_init();
        mushroomNft = MushroomNFT(mushroomNft_);
    }

    function getMushroomData(uint256 index, bytes calldata data) external view override returns (MushroomLib.MushroomData memory) {
        MushroomLib.MushroomData memory mData = mushroomNft.getMushroomData(index);
        return mData;
    }
    function setMushroomLifespan(uint256 index, uint256 lifespan, bytes calldata data) external override {
        mushroomNft.setMushroomLifespan(index, lifespan);
    }
}