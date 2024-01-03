// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./AccessControl.sol";
import "./ERC721.sol";
import "./MushroomLib.sol";

/*
    Minting and burning permissions are managed by the Owner
*/
contract MushroomNFT is ERC721UpgradeSafe, OwnableUpgradeSafe, AccessControlUpgradeSafe {
    using MushroomLib for MushroomLib.MushroomData;
    using MushroomLib for MushroomLib.MushroomType;

    mapping (uint256 => MushroomLib.MushroomData) public mushroomData; // NFT Id -> Metadata
    mapping (uint256 => MushroomLib.MushroomType) public mushroomTypes; // Species Id -> Metadata
    mapping (uint256 => bool) public mushroomTypeExists; // Species Id -> Exists
    mapping (uint256 => string) public mushroomMetadataUri; // Species Id -> URI

    bytes32 public constant LIFESPAN_MODIFIER_ROLE = keccak256("LIFESPAN_MODIFIER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function initialize() public initializer {
        __Ownable_init_unchained();
        __AccessControl_init_unchained();
        __ERC721_init("Enoki Mushrooms", "Enoki Mushrooms");

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

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

    /// @notice Return token URI for mushroom
    /// @notice URI is determined by species and can be modifed by the owner
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        MushroomLib.MushroomData storage data = mushroomData[tokenId];
        return mushroomMetadataUri[data.species];
    }  

    /* ========== ROLE MANAGEMENT ========== */

    // TODO: Ensure we can transfer admin role privledges

    modifier onlyLifespanModifier() {
        require(hasRole(LIFESPAN_MODIFIER_ROLE, msg.sender), "MushroomNFT: Only approved lifespan modifier");
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "MushroomNFT: Only approved mushroom minter");
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev The burner must be the owner of the token, or approved. The EnokiGeyser owns tokens when it burns them.
     */
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
        _clearMushroomData(tokenId);
    }

    function mint(address recipient, uint256 tokenId, uint256 speciesId, uint256 lifespan) public onlyMinter {
        _mintWithMetadata(recipient, tokenId, speciesId, lifespan);
    }

    function setMushroomLifespan(uint256 index, uint256 lifespan) public onlyLifespanModifier {
        mushroomData[index].lifespan = lifespan;
    }

    function setSpeciesUri(uint256 speciesId, string memory URI) public onlyOwner {
        mushroomMetadataUri[speciesId] = URI;
    }

    function _mintWithMetadata(address recipient, uint256 tokenId, uint256 speciesId, uint256 lifespan) internal {
        require(mushroomTypeExists[speciesId], "MushroomNFT: mushroom species specified does not exist");
        MushroomLib.MushroomType storage species = mushroomTypes[speciesId];

        require(species.minted < species.cap, "MushroomNFT: minting cap reached for species");

        species.minted = species.minted.add(1);
        mushroomData[tokenId] = MushroomLib.MushroomData(speciesId, species.strength, lifespan);

        _safeMint(recipient, tokenId);
    }

    // TODO: We don't really have to do this as a newly minted mushroom will set the data
    function _clearMushroomData(uint256 tokenId) internal {
        MushroomLib.MushroomData storage data = mushroomData[tokenId];
        MushroomLib.MushroomType storage species = mushroomTypes[data.species];   

        mushroomData[tokenId].species = 0;
        mushroomData[tokenId].strength = 0;
        mushroomData[tokenId].lifespan = 0;

        species.minted = species.minted.sub(1);
    }
    function setMushroomType(uint256 speciesId, MushroomLib.MushroomType memory mType) public onlyOwner {
        if (!mushroomTypeExists[speciesId]) {
            mushroomTypeExists[speciesId] = true;
        }

        mushroomTypes[speciesId] = mType;
    }
}