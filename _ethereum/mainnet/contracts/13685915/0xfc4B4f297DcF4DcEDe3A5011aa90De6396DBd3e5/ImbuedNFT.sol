//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

/** @title NFT contract for imbued works of art
    @author 0xsublime.eth
    @notice This contract is the persistent center of the Imbued Art project,
    and allows unstoppable ownership of the NFTs. The minting is controlled by a
    separate contract, which is upgradeable. This contract enforces a 700 token
    limit: 7 editions of 100 tokens.

    The dataContract is intended to serve as a store for metadata, animations,
    code, etc.

    The owner of a token can imbue it with meaning. The imbuement is a string,
    up to 32 bytes long. The history of a tokens owenrship and its imbuements
    are stored and are retrievable via view functions.

    Token transfers are initially turned off for all editions. Once a transfers
    are activated on an edition of tokens, it cannot be disallowed again.
 */
contract ImbuedNFT is ERC721Enumerable, Ownable {

    /// @dev The contract controlling minting
    address public mintContract;
    /// @dev For storing metadata, animations, code.
    address public dataContract; 

    uint256 constant public NUM_EDITIONS = 7;
    uint256 constant public EDITION_SIZE = 100;
    /// Tokens are marked transferable at the edition level.
    bool[] public editionTransferable = new bool[](NUM_EDITIONS);

    string public baseURI = "https://api.imbuedart.com/api/token/";

    /// Maps a token to its history of owners.
    mapping (uint256 => address[]) public id2provenance;
    /// Maps a (token, owner) pair to its imbuement.
    mapping (uint256 => mapping (address => string)) public idAndOwner2imbuement;

    event Imbued(uint256 indexed tokenId, address indexed owner, string imbuement);
    event EditionTransferable(uint256 indexed edition);

    constructor() ERC721("Imbued Art", "IMBUED") { }

    // ===================================
    // Mint contract privileged functions.
    // ===================================

    /** @dev The mint function can only be called by the minter address.
        @param recipient The recipient of the minted token, needs to be an EAO or a contract which accepts ERC721s.
        @param tokenId The token ID to mint.
     */
    function mint(address recipient, uint256 tokenId) external {
        require(msg.sender == mintContract, "Only the mint contract can mint");
        require(tokenId < NUM_EDITIONS * EDITION_SIZE, "Token ID is too high");
        id2provenance[tokenId].push(recipient);
        _safeMint(recipient, tokenId);
    }

    // ==============
    // NFT functions.
    // ==============

    /** Saves an imbuement for a token and owner.
        An imbuement is a string, up to 32 bytes (equivalent to 32 ASCII
        characters).  Once set, it is immuatble.  Only the owner, or an address
        which has permission to control the token, can imbue it.
        @param tokenId The token to imbue.
        @param imbuement The string that should be saved
     */
    function imbue(uint256 tokenId, string calldata imbuement) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Can only imbue token you control");
        require(bytes(imbuement).length <= 32, "Only 32 bytes allowed.");
        address own = ownerOf(tokenId);
        string storage currentImbuement = idAndOwner2imbuement[tokenId][own];
        require(keccak256((abi.encodePacked(currentImbuement))) == keccak256(abi.encodePacked(""))
            , "One imbument per token and owner");
        idAndOwner2imbuement[tokenId][own] = imbuement;
        emit Imbued(tokenId, own, imbuement);
    }

    /// @dev Tokens transfers are initially blocked. Once released, they are always transferable.
    function _transfer(address from, address to, uint256 id) internal override {
        require(editionTransferable[id / EDITION_SIZE], "Edition transfer not active");
        id2provenance[id].push(to);
        super._transfer(from, to, id);
    }

    // ===============
    // View functions.
    // ===============

    /// Get the complete list of imbuements for a token.
    /// @param id ID of the token to get imbuements for
    /// @param start start of the range to return (inclusive)
    /// @param end end of the range to return (non-inclusive), or 0 for max length.
    /// @return A string array, each string at most 32 bytes.
    function imbuements(uint256 id, uint256 start, uint256 end) external view returns (string[] memory) {
        address own;
        address[] storage owners = id2provenance[id];
        if (end == 0) {
            end = owners.length;
        }
        string[] memory result = new string[](end - start);
        for (uint256 i = start; i < end; i++) {
            own = owners[i];
            result[i - start] = idAndOwner2imbuement[id][own];
        }
        return result;
    }

    /// Get the chronological list of owners of a token.
    /// @param id The token ID to get the provenance for.
    /// @param start start of the range to return (inclusive)
    /// @param end end of the range to return (non-inclusive), or 0 for max length.
    /// @return An address array of all owners, listed chornologically.
    function provenance(uint256 id, uint256 start, uint256 end) external view returns (address[] memory) {
        address own;
        address[] storage owners = id2provenance[id];
        if (end == 0) {
            end = owners.length;
        }
        address[] memory result = new address[](end - start);
        for (uint256 i = start; i < end; i++) {
            own = owners[i];
            result[i - start] = own;
        }
        return result;
    }

    // ==========================
    // Internal helper functions.
    // ==========================

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // =====================
    // Only owner functions.
    // =====================

    function setMintContract(address _mintContract) external onlyOwner() {
        mintContract = _mintContract;
    }

    function setDataContract(address _dataContract) external onlyOwner() {
        dataContract = _dataContract;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner() {
        baseURI = newBaseURI;
    }

    /// @dev Edition transfers can only be allowed, there is no way to disallow them later.
    function setEditionTransferable(uint256 edition) external onlyOwner {
        editionTransferable[edition] = true;
        emit EditionTransferable(edition);
    }
}