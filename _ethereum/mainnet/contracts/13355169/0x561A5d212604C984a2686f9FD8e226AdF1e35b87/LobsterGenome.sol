// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Ownable.sol";

/**
* @title LobsterBeachClub interface
*/
interface ILobsterBeachClub {
    function seedNumber() external view returns (uint256);
    function maxSupply() external view returns (uint256);
}

/**
* @title LobsterGenome contract
* @dev Handles lobster traits, assets and constructing gene sequences
*/
contract LobsterGenome is Ownable {
    // mapping of gene sequence to traits / rarities
    mapping(uint => uint16[]) public traits;
    // mapping of gene sequence to sum of all rarities
    mapping(uint => uint16) public sequenceToRarityTotals;
    // provenance record of images and metadata
    string public provenance;
    // list of gene sequences
    uint16[] sequences;
    // list of assets
    uint16[] assets;
    ILobsterBeachClub public lobsterBeachClub;

    constructor(address lbcAddress) {
        setLobsterBeachClub(lbcAddress);
    }

    function setLobsterBeachClub(address lbcAddress) public onlyOwner {
        lobsterBeachClub = ILobsterBeachClub(lbcAddress);
    }

    function setProvenance(string memory _provenance) public onlyOwner {
        provenance = _provenance;
    }

    /**
    * @dev reset traits and rarities
    */
    function resetTraits() public onlyOwner {
        for(uint i; i < sequences.length; i++) {
            delete traits[i];
            delete sequenceToRarityTotals[i];
        }
        delete sequences;
    }

    /**
    * @dev set available traits and rarities at the same time
    * @dev example: [500, 500, 0, 100, 300, 600] sets two sequences separated by '0'
    *               [500, 500], [100, 300, 600] sequence 0 and 1, index is trait value is rarity
    */
    function setTraits(uint16[] memory rarities) public onlyOwner {
        require(rarities.length > 0, "Rarities is empty, Use resetTraits() instead");
        resetTraits();
        uint16 trait = 0;
        sequences.push(trait);
        for(uint i; i < rarities.length; i++) {
            uint16 rarity = rarities[i];
            if (rarity == 0) {
                trait++;
                sequences.push(trait);
            } else {
                traits[trait].push(rarity);
                sequenceToRarityTotals[trait] += rarity;
            }
        }
    }

    /**
    * @dev Returns the sequence for a given tokenId
    * @dev Deterministic based on tokenId and seedNumber from lobsterBeachClub
    * @dev One trait is selected and appended to sequence based on rarity
    * @dev Returns geneSequence of asset if tokenId is chosen for an asset
    */
    function getGeneSequence(uint256 tokenId) public view returns (uint256 _geneSequence) {
        uint256 assetOwned = getAssetOwned(tokenId);
        if (assetOwned != 0) {
            return assetOwned;
        }
        uint256 seedNumber = lobsterBeachClub.seedNumber();
        uint256 geneSequenceSeed = uint256(keccak256(abi.encode(seedNumber, tokenId)));
        uint256 geneSequence;
        for(uint i; i < sequences.length; i++) {
            uint16 sequence = sequences[i];
            uint16[] memory rarities = traits[sequence];
            uint256 sequenceRandomValue = uint256(keccak256(abi.encode(geneSequenceSeed, i)));
            uint256 sequenceRandomResult = (sequenceRandomValue % sequenceToRarityTotals[sequence]) + 1;
            uint16 rarityCount;
            uint resultingTrait;
            for(uint j; j < rarities.length; j++) {
                uint16 rarity = rarities[j];
                rarityCount += rarity;
                if (sequenceRandomResult <= rarityCount) {
                    resultingTrait = j;
                    break;
                }
            }
            geneSequence += 10**(3*sequence) * resultingTrait;
        }
        return geneSequence;
    }

    /**
    * @dev Set geneSequences of assets available
    * @dev Used as 1 of 1s or 1 of Ns (N being same geneSequence repeated N times)
    */
    function setAssets(uint16[] memory _assets) public onlyOwner {
        uint256 maxSupply = lobsterBeachClub.maxSupply();
        require(_assets.length <= maxSupply, "You cannot supply more assets than max supply");
        for (uint i; i < _assets.length; i++) {
            require(_assets[i] > 0 && _assets[i] < 1000, "Asset id must be between 1 and 999");
        }
        assets = _assets;
    }
    
    /**
    * @dev Deterministically decides which tokenIds of maxSupply from lobsterBeachClub will receive each asset
    * @dev Determination is based on seedNumber
    * @dev To prevent from tokenHolders knowing which section of tokenIds are more likely to receive an asset
    *      the direction which assets are chosen from 0 or maxSupply is also deterministic on the seedNumber
    */
    function getAssetOwned(uint256 tokenId) public view returns (uint16 assetId) {
        uint256 maxSupply = lobsterBeachClub.maxSupply();
        uint256 seedNumber = lobsterBeachClub.seedNumber();
        uint256 totalDistance = maxSupply;
        uint256 direction = seedNumber % 2;
        for (uint i; i < assets.length; i++) {
            uint256 difference = totalDistance / (assets.length - i);
            uint256 assetSeed = uint256(keccak256(abi.encode(seedNumber, i)));
            uint256 distance = (assetSeed % difference) + 1;
            totalDistance -= distance;
            if ((direction == 0 && totalDistance == tokenId) || (direction == 1 && (maxSupply - totalDistance - 1 == tokenId))) {
                return assets[i];
            }
        }
        return 0;
    }

}