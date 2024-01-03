// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";
// import "./AccessControl.sol";

import "./MushroomNFT.sol";
import "./MushroomLib.sol";
import "./MetadataAdapter.sol";

/*
    Reads mushroom NFT metadata directly from the Mushroom NFT contract
    Also forwards requests from the MetadataResolver to a given forwarder, that cannot be modified
*/

contract MushroomAdapter is Initializable, MetadataAdapter {
    using MushroomLib for MushroomLib.MushroomData;
    using MushroomLib for MushroomLib.MushroomType;

    MushroomNFT public mushroomNft;

    function initialize(address nftContract_, address forwardActionsFrom_) public initializer {
        mushroomNft = MushroomNFT(nftContract_);
        _setupRole(LIFESPAN_MODIFY_REQUEST_ROLE, forwardActionsFrom_);
    }

    function getMushroomData(uint256 index, bytes calldata data) external override view returns (MushroomLib.MushroomData memory) {
        MushroomLib.MushroomData memory mData = mushroomNft.getMushroomData(index);
        return mData;
    }

    // Mushrooms can always be staked
    function isStakeable(uint256 nftIndex) external override view returns (bool) {
        return true;
    }

    // All Mushrooms are burnable
    function isBurnable(uint256 index) external override view returns (bool) {
        return true;
    }

    function setMushroomLifespan(
        uint256 index,
        uint256 lifespan,
        bytes calldata data
    ) external override onlyLifespanModifier {
        mushroomNft.setMushroomLifespan(index, lifespan);
    }
}
