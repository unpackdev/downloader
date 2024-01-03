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
contract MushroomLifespanMock is Initializable, OwnableUpgradeSafe {
    using MushroomLib for MushroomLib.MushroomData;
    using MushroomLib for MushroomLib.MushroomType;
    using SafeMath for uint256;

    uint256 public spawnCount;

    event MushroomGrown(address recipient, uint256 id, uint256 species, uint256 lifespan);

    function generateMushroomLifespan(uint256 minLifespan, uint256 maxLifespan) public returns (uint256) {
        uint256 range = maxLifespan.sub(minLifespan);
        uint256 fromMin = uint256(keccak256(abi.encodePacked(block.timestamp.add(spawnCount)))) % range;
        spawnCount = spawnCount.add(1);

        return minLifespan.add(fromMin);
    }

    function getRemainingMintableForMySpecies(MushroomNFT mushroomNft, uint256 speciesId) public view returns (uint256) {
        return mushroomNft.getRemainingMintableForSpecies(speciesId);
    }

    // Each mushroom costs 1/10th of the spore rate in spores.
    function growMushrooms(MushroomNFT mushroomNft, uint256 speciesId, address recipient, uint256 numMushrooms) public {
        MushroomLib.MushroomType memory species = mushroomNft.getSpecies(speciesId);

        require(getRemainingMintableForMySpecies(mushroomNft, speciesId) >= numMushrooms, "MushroomFactory: Mushrooms to grow exceeds species cap");
        for (uint256 i = 0; i < numMushrooms; i++) {
            uint256 nextId = mushroomNft.totalSupply().add(1);

            uint256 lifespan = generateMushroomLifespan(species.minLifespan, species.maxLifespan);
            mushroomNft.mint(recipient, nextId, speciesId, lifespan);
            emit MushroomGrown(recipient, nextId, speciesId, lifespan);
        }
    }
}