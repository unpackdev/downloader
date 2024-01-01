// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

/**
 * @title GomemeNFT Contract for meme NFTs
 * @author The Tech Alchemy Team
 * @notice The GomemeNFT contract mints NFTs for users.
 * @dev All function calls are currently implemented without side effects
 */

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";

import "./GomemeNFTInterface.sol";

contract GomemeNFT is
    ERC721Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    GomemeNFTInterface
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /**
     * @dev Counter for maintaining TokenIds
     */
    CountersUpgradeable.Counter public tokenIdCounter;

    /**
     *  @dev Mapping for maintaing uri for each NFT token based on token Id
     */
    mapping(uint256 => string) internal tokenUri;

    /**
     *  @dev Initialize token name and token symbol
     *  @param name Token Name
     *  @param symbol Token Symbol
     */
    function initialize(
        string memory name,
        string memory symbol
    ) public initializer {
        require(
            bytes(name).length > 0,
            "GomemeNFT: Name parameter can not be empty"
        );
        require(
            bytes(symbol).length > 0,
            "GomemeNFT: Symbol parameter can not be empty"
        );
        __ERC721_init(name, symbol);
        __Pausable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /**
     * @dev User mint a new NFT for the meme created.
     * @param tokenMetadata The metadata uri for the token id.
     */
    function mint(
        string memory tokenMetadata
    ) external override whenNotPaused returns (uint256) {
        tokenIdCounter.increment();
        uint256 tokenId = tokenIdCounter.current();
        tokenUri[tokenId] = tokenMetadata;
        _safeMint(_msgSender(), tokenId);
        emit NewNFTMinted(tokenId);
        return tokenId;
    }

    /**
     * @notice This function is used to check uri of specific token by giving tokenId.
     * @dev This function returns the token uri by giving tokenId.
     * @param tokenId tokenId is given to the function to get corresponding uri.
     */
   
   function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "GomemeNFT: Non-existent token.");
        return tokenUri[tokenId];
   }

    /**
     * @dev Pauses the contract, preventing certain functions from being executed.
     * @dev Only owner can call this function.
     */
    function pause() public override onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing the execution of all functions.
     * @dev Only owner can call this function.
     */
    function unpause() public override onlyOwner {
        _unpause();
    }
}
