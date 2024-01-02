// SPDX-License-Identifier: MIT
// Clopr Contracts

pragma solidity 0.8.21;

import "./IERC721.sol";

/**
 * @title ICloprStories
 * @author Pybast.eth - Nefture
 * @custom:lead Antoine Bertin - Clopr
 * @dev Manages the lifecycle and properties of CloprStories, unique NFTs with evolving stories tied to specific assets, representing a novel form of asset-driven narrative.
 */
interface ICloprStories {
    /// @notice struct to store stories' information
    /// @param unftTokenId token ID of the story's underlying NFT
    /// @param unftContract contract address of the story's underlying NFT
    /// @param storyCompletionTime timestamp at which the story will be complete
    /// @param maxStoryLength maximum number of pages (length) of the story
    /// @param metadataUri URI of the story's metadata if it has been decentralized with `setImmutableTokenURI`
    struct StoryInformation {
        uint256 unftTokenId;
        IERC721 unftContract;
        uint48 storyCompletionTime;
        uint24 maxStoryLength; // uint24 is enough because in the case if all 50,000 stories are merged, the theoretical unique story will be 300000 pages
        string metadataUri;
    }

    /// @notice thrown if the given vault is not delegated to the caller
    error InvalidDelegateVaultPairing();

    /// @notice thrown if the story doesn't exist
    error StoryDoesntExist();

    /// @notice thrown if the caller doesn't own the story
    error DontOwnStory();

    /// @notice thrown if the caller is not authorised
    error NotAuthorised();

    /// @notice thrown if the story is not complete
    error StoryNotCompleted();

    /// @notice thrown if trying to create the ClopStory of a CloprStory
    error CantCreateStoryOfStory();

    /// @notice thrown if trying to create a CloprStory of a non ERC721 contract
    error NotErc721Contract();

    /// @notice thrown if trying to burn and grow the same CloprStory
    error NeedDifferentTokenIds();

    /// @notice thrown if trying to create a CloprStory of an ERC721 token you don't own
    error DontOwnNft();

    /// @notice thrown if trying to transfer a CloprStory to its owner
    error TokenAlreadyOwned();

    /// @notice thrown if trying to burn a CloprStory not owned
    error CallerNotOwner();

    /// @notice thrown if trying to transfer a CloprStory
    error CantTransferCloprStories();

    /// @notice thrown if the CloprStory's underlying NFT doesn't exist
    error UNFTDoesntExist();

    /// @notice thrown if trying to approve or setApprovalForAll a CloprStory
    error CantApproveStories();

    /// @notice thrown if trying to set the baseUri as an empty string
    error BaseUriCantBeNull();

    /// @notice emitted when a CloprStory is created
    /// @param nftContractAddress contract address of the CloprStory's underlying NFT
    /// @param nftTokenId token ID of the CloprStory's underlying NFT
    /// @param storyTokenId token ID of the newly created CloprStory
    /// @param bottleTokenId token ID of the bottle used to create the CloprStory
    event CreateStory(
        address indexed nftContractAddress,
        uint256 indexed nftTokenId,
        uint256 indexed storyTokenId,
        uint256 bottleTokenId
    );

    /// @notice emitted when a CloprStory is extended
    /// @param burnedTokenId token ID of the burned CloprStory
    /// @param extendedTokenId token ID of the extended CloprStory
    /// @param newMaxLength new maximum number of pages (length) of the extended CloprStory
    event ExtendStory(
        uint256 indexed burnedTokenId,
        uint256 indexed extendedTokenId,
        uint24 newMaxLength
    );

    /// @notice emitted when a CloprStory gets a decentralized token URI
    /// @param tokenId token ID of the CloprStory
    event SetImmutableTokenURI(uint256 indexed tokenId);

    /// @notice emitted when the base URI is modified
    /// @param newDefaultBaseUri new base URI
    event NewDefaultBaseUri(string newDefaultBaseUri);

    /**
     * ----------- EXTERNAL -----------
     */

    /// @notice Create a Clopr Story and associate it with an NFT by drinking a Clop Bottle filled with StoryPotion
    /// @dev Emits an event to enable tracking story creation
    /// @param bottleTokenId CloprBottles to use to create the story
    /// @param contractAddress contract address of the NFT being associated with the Clopr Story
    /// @param nftTokenId token ID of the NFT being associated with the Clopr Story
    /// @param vault Delegate Cash vault to use as a delegated wallet
    function createStory(
        uint256 bottleTokenId,
        IERC721 contractAddress,
        uint256 nftTokenId,
        address vault
    ) external;

    /// @notice Burn a Clopr Story to extend the maximum number of pages of another Clopr Story
    /// @dev Emits an event to enable tracking Clopr Story burns and page extensions
    /// @param burnedTokenId token ID of the Clopr Story being burned
    /// @param extendedTokenId token ID of the Clopr Story being extended
    /// @param vault1 Delegate Cash vault to use as a delegated wallet for the burned Clopr Story
    /// @param vault2 Delegate Cash vault to use as a delegated wallet for the extended Clopr Story
    function burnAndGrowStory(
        uint256 burnedTokenId,
        uint256 extendedTokenId,
        address vault1,
        address vault2
    ) external;

    /// @notice Enables the decentralisation of a token's metadata
    /// @dev A signature, by a trusted third party, is necessary to decentralise a tokens' metadata.
    ///      Emits an event to enable tracking token decentralisation
    /// @param tokenId token ID for which to decentralise the metadata
    /// @param metadataUri new token's metadata URI
    /// @param signature signature that allows the sender to set its immutable token URI
    function setImmutableTokenURI(
        uint256 tokenId,
        string calldata metadataUri,
        bytes calldata signature,
        address vault
    ) external;

    /**
     * ----------- ADMIN -----------
     */

    /// @notice Get a Clopr Story's metadata URI
    /// @dev Don't forget the trailing slash in the base URI as it will be concatenated with other information.
    ///      Emits an event to enable tracking base URI changes
    /// @param newDefaultBaseUri token ID of the story
    function changeDefaultBaseUri(string memory newDefaultBaseUri) external;

    /// @dev Used to emit an ERC-4906 event if the metadata are modified off chain
    function offchainMetadataUpdate() external;

    /**
     * ----------- ENUMERATIONS -----------
     */

    /// @notice Get all information of a story
    /// @param tokenId token ID of the story
    /// @return unftContract address of the NFT smart contract associated with the story
    /// @return unftTokenId token ID of the NFT smart contract associated with the story
    /// @return storyLength number of pages of the story
    /// @return maxStoryLength maximum number of pages of the story
    function getStoryInformation(
        uint256 tokenId
    )
        external
        view
        returns (
            IERC721 unftContract,
            uint256 unftTokenId,
            uint256 storyLength,
            uint24 maxStoryLength
        );

    /// @notice Get the UNFT of a story
    /// @param tokenId token ID of the story
    /// @return unftContract address of the NFT smart contract associated with the story
    /// @return unftTokenId token ID of the NFT smart contract associated with the story
    function getUnft(
        uint256 tokenId
    ) external view returns (IERC721 unftContract, uint256 unftTokenId);

    /// @notice Get the UNFT's contract address of a story
    /// @param tokenId token ID of the story
    /// @return unftContract address of the NFT smart contract associated with the story
    function getUnftContract(
        uint256 tokenId
    ) external view returns (IERC721 unftContract);

    /// @notice Get the UNFT's token ID of a story
    /// @param tokenId token ID of the story
    /// @return unftTokenId token ID of the NFT smart contract associated with the story
    function getUnftTokenId(
        uint256 tokenId
    ) external view returns (uint256 unftTokenId);

    /// @notice Get a story's length
    /// @param tokenId token ID of the story
    /// @return storyLength number of pages of the story
    function getStoryLength(
        uint256 tokenId
    ) external view returns (uint256 storyLength);

    /// @notice Get a story's maximum length
    /// @param tokenId token ID of the story
    /// @return maxStoryLength maximum number of pages of the story
    function getMaxStoryLength(
        uint256 tokenId
    ) external view returns (uint256 maxStoryLength);
}
