// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

import "./MushroomNFT.sol";
import "./MushroomLib.sol";

/*
    MushroomFactories manage the mushroom generation logic for pools
    Each pool will have it's own factory to generate mushrooms according
    to its' powers.

    The mushroomFactory should be administered by the pool, which grants the ability to grow mushrooms
*/
contract MushroomFactory is Initializable, OwnableUpgradeSafe {
    using MushroomLib for MushroomLib.MushroomData;
    using MushroomLib for MushroomLib.MushroomType;
    using SafeMath for uint256;

    event MushroomGrown(address recipient, uint256 id, uint256 species, uint256 lifespan);

    IERC20 public sporeToken;
    MushroomNFT public mushroomNft;

    uint256 public costPerMushroom;
    uint256 public mySpecies;

    uint256 public spawnCount;

    function initialize(
        IERC20 sporeToken_,
        MushroomNFT mushroomNft_,
        address sporePool_,
        uint256 costPerMushroom_,
        uint256 mySpecies_
    ) public initializer {
        __Ownable_init();
        sporeToken = sporeToken_;
        mushroomNft = mushroomNft_;
        costPerMushroom = costPerMushroom_;
        mySpecies = mySpecies_;
        transferOwnership(sporePool_);
    }

    /*
        Each mushroom will have a randomly generated lifespan within it's range. To prevent mushrooms harvested at the same block from having the same properties, a spawnCount seed is added to the block timestamp before hashing the timestamp to generate the lifespan for each individual mushroom.

        Note that block.timestamp is somewhat manipulatable by Miners. If a Miner was a massive ENOKI fan and only harvested when the mined a block they could give themselves mushrooms with longer lifespan than the average. However, the lifespan is still constained by the max lifespan. 
    */
    function _generateMushroomLifespan(uint256 minLifespan, uint256 maxLifespan) internal returns (uint256) {
        uint256 range = maxLifespan.sub(minLifespan);
        uint256 fromMin = uint256(keccak256(abi.encodePacked(block.timestamp.add(spawnCount)))) % range;
        spawnCount = spawnCount.add(1);

        return minLifespan.add(fromMin);
    }

    function getRemainingMintableForMySpecies() public view returns (uint256) {
        return mushroomNft.getRemainingMintableForSpecies(mySpecies);
    }

    // Each mushroom costs 1/10th of the spore rate in spores.
    function growMushrooms(address recipient, uint256 numMushrooms) public onlyOwner {
        MushroomLib.MushroomType memory species = mushroomNft.getSpecies(mySpecies);

        require(getRemainingMintableForMySpecies() >= numMushrooms, "MushroomFactory: Mushrooms to grow exceeds species cap");
        for (uint256 i = 0; i < numMushrooms; i++) {
            uint256 nextId = mushroomNft.totalSupply().add(1);

            uint256 lifespan = _generateMushroomLifespan(species.minLifespan, species.maxLifespan);
            mushroomNft.mint(recipient, nextId, mySpecies, lifespan);
            emit MushroomGrown(recipient, nextId, mySpecies, lifespan);
        }
    }
}