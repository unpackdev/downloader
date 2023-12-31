pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./ERC721.sol";
import "./MushroomLib.sol";

/*
    Minting and burning permissions are managed by the Owner
*/
contract MushroomNFT is ERC721("Mushroom", "Mushroom"), Ownable {
    using MushroomLib for MushroomLib.MushroomData;
    using MushroomLib for MushroomLib.MushroomType;

    mapping (uint256 => MushroomLib.MushroomData) public mushroomData; // NFT Id -> Metadata
    mapping (uint256 => MushroomLib.MushroomType) public mushroomTypes; // Species Id -> Metadata
    mapping (uint256 => bool) public mushroomTypeExists; // Species Id -> Exists

    /* ========== VIEWS ========== */

    // Mushrooms inherit their strength from their species
    function getMushroomData(uint256 tokenId) public view returns (MushroomLib.MushroomData memory) {
        MushroomLib.MushroomData memory data = mushroomData[tokenId];
        return data;
    }

    function getSpecies(uint256 speciesId) public view returns (MushroomLib.MushroomType memory) {
        return mushroomTypes[speciesId];
    }

    function getRemainingMintableForSpecies(uint256 speciesId) public view returns (uint256) {
        MushroomLib.MushroomType storage species = mushroomTypes[speciesId];
        return species.cap.sub(species.minted);
    }
    
    // TODO: Allowed approved contracts to set lifespan
    function setMushroomLifespan(uint256 index, uint256 lifespan) public onlyOwner {
        MushroomLib.MushroomData storage data = mushroomData[index];
        data.lifespan = lifespan;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}. Also clears mushroom data for this token.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
        _clearMushroomData(tokenId);
    }

    // TODO: Approved Minters only
    function mint(address recipient, uint256 tokenId, uint256 speciesId, uint256 lifespan) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _mintWithMetadata(recipient, tokenId, speciesId, lifespan);
    }

    function _mintWithMetadata(address recipient, uint256 tokenId, uint256 speciesId, uint256 lifespan) internal {
        require(mushroomTypeExists[speciesId], "MushroomNFT: mushroom species specified does not exist");
        MushroomLib.MushroomType storage species = mushroomTypes[speciesId];

        require(species.minted < species.cap, "MushroomNFT: minting cap reached for species");

        species.minted = species.minted.add(1);
        mushroomData[tokenId] = MushroomLib.MushroomData(speciesId, species.strength, lifespan);

        _mint(recipient, tokenId);
    }

    // TODO: We don't really have to do this as a newly minted mushroom will set the data
    function _clearMushroomData(uint256 tokenId) internal {
        MushroomLib.MushroomData storage data = mushroomData[tokenId];
        MushroomLib.MushroomType storage species = mushroomTypes[data.species];     

        species.minted = species.minted.sub(1);
    }
    function setMushroomType(uint256 speciesId, MushroomLib.MushroomType memory mType) public onlyOwner {
        if (!mushroomTypeExists[speciesId]) {
            mushroomTypeExists[speciesId] = true;
        }

        mushroomTypes[speciesId] = mType;
    }
}