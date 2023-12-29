// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./LibString.sol";
import "./ERC721.sol";

import "./Create2Ownable.sol";
import "./Constants.sol";
import "./GameRegistryConsumer.sol";

import "./IHoneyJar.sol";

/// @title BearPunk (HoneyJar)
/// @notice A stand-alone ERC721 compliant NFT
/// @dev xChain functionality is abstracted away from NFT implementation into a separate contract
/// @dev can safely be deployed along with HoneyJarPortal to every chain.
contract BeraPunk is IHoneyJar, ERC721, GameRegistryConsumer, Create2Ownable {
    using LibString for uint256;

    /**
     * Errors
     */
    error MaxMintLimitReached(uint256 mintNum);
    error URIQueryForNonexistentToken();

    /**
     * Events
     */
    event SetGenerated(bool generated);
    event BaseURISet(string uri);

    // Needed to prevent cross chain collisions
    uint256 public immutable startingTokenId;
    uint256 public immutable maxTokenId;
    uint256 internal _nextTokenId;

    /// @notice The tokenID space needs to be segmented for each chain
    constructor(address owner_, address gameRegistry_, uint256 startTokenId_, uint256 mintAmount_)
        ERC721("Bera Punk", "BPUNK")
        GameRegistryConsumer(gameRegistry_)
        Create2Ownable(owner_)
    {
        startingTokenId = startTokenId_;
        _nextTokenId = startTokenId_;
        maxTokenId = startTokenId_ + mintAmount_ - 1;
    }

    /// @notice view function for frontend
    function nextTokenId() external view override returns (uint256) {
        return _nextTokenId;
    }

    // metadata URI
    string internal baseTokenURI = "https://www.0xhoneyjar.xyz/";
    bool public isGenerated; // once the token is generated we can append individual tokenIDs

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI_) external onlyRealOwner {
        baseTokenURI = baseURI_;
        emit BaseURISet(baseURI_);
    }

    function setGenerated(bool generated_) external onlyRealOwner {
        isGenerated = generated_;
        emit SetGenerated(generated_);
    }

    /// @notice Token URI will be a generic URI at first.
    /// @notice When isGenerated is set to true, it will concat the baseURI & tokenID
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return isGenerated ? string.concat(baseURI, tokenId.toString()) : baseURI;
    }

    /// @notice Mint your ONFT
    function mintOne(address to) public override onlyRole(Constants.MINTER) returns (uint256) {
        if (_nextTokenId > maxTokenId) revert MaxMintLimitReached(maxTokenId);

        uint256 newId = _nextTokenId;
        ++_nextTokenId;

        _safeMint(to, newId);
        return newId;
    }

    /// @notice Used for xChain calls
    function mintTokenId(address to, uint256 tokenId_) external override onlyRole(Constants.MINTER) {
        _safeMint(to, tokenId_);
    }

    /// @notice mint multiple.
    /// @dev only callable by the MINTER role
    function batchMint(address to, uint256 amount) external override onlyRole(Constants.MINTER) {
        for (uint256 i = 0; i < amount; ++i) {
            mintOne(to);
        }
    }

    /// @notice burn the honeyjar tokens. Nothing will have the burn role upon initialization
    /// @notice This will be used for future game-mechanics
    /// @dev only callable by the BURNER role
    function burn(uint256 _id) external override onlyRole(Constants.BURNER) {
        _burn(_id);
    }
}
