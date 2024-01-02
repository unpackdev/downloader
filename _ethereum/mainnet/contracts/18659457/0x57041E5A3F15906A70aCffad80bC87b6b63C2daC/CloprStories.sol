// SPDX-License-Identifier: MIT
// Clopr Contracts

pragma solidity 0.8.21;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./AccessControl.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./ERC165.sol"; // import for natSpecs
import "./IERC721Metadata.sol";
import "./IERC721.sol";
import "./IAccessControl.sol";
import "./IERC165.sol";
import "./ICloprStories.sol";
import "./ICloprBottles.sol";
import "./IDelegateRegistry.sol";
import "./IERC4906.sol";

/**
 * @title CloprStories
 * @author Pybast.eth - Nefture
 * @custom:lead Antoine Bertin - Clopr
 * @dev Manages the lifecycle and properties of CloprStories, unique NFTs with evolving stories tied to specific assets, representing a novel form of asset-driven narrative.
 */
contract CloprStories is
    ERC721,
    ERC721Burnable,
    Ownable,
    AccessControl,
    ICloprStories,
    IERC4906
{
    /// @dev total number of tokens
    uint32 private currentSupply;

    /// @dev base URI used to retrieve tokens' metadata if they are not decentralized
    ///      with setImmutableTokenURI function
    string private defaultBaseUri;

    /// @dev role to give the authorisation to decentralize a token's metadata
    bytes32 private constant SIGNER_IMMUTABLE_METADATA_ROLE =
        keccak256("SIGNER_IMMUTABLE_METADATA_ROLE");

    uint16 public constant STORY_POTION_ID = 42;

    /// @dev delegate cash V2 contract
    IDelegateRegistry private constant DC =
        IDelegateRegistry(0x00000000000000447e69651d841bD8D104Bed493);

    /// @dev CloprBottles' smart contract address
    ICloprBottles private constant BOTTLES_CONTRACT =
        ICloprBottles(0xB0711E51eef597FA03bfF2CbFea3Dc4d3C4f6906);

    /// @dev stores CloprStories information
    mapping(uint256 tokenId => StoryInformation storyInformation)
        private stories;

    /// @dev stores nonces to make sure setImmutableTokenURI's signatures can only be used once
    mapping(uint256 tokenId => uint256 nonce) private signatureNonce;

    constructor(
        string memory startDefaultBaseUri
    ) ERC721("CloprStories", "CSTR") {
        if (bytes(startDefaultBaseUri).length == 0) revert BaseUriCantBeNull();

        defaultBaseUri = startDefaultBaseUri;

        _grantRole(
            DEFAULT_ADMIN_ROLE,
            0x799B7627f972dcf97b00bBBC702b2AD1b7546519
        );
        _transferOwnership(0x799B7627f972dcf97b00bBBC702b2AD1b7546519);
    }

    /**
     * ----------- EXTERNAL -----------
     */

    /// @inheritdoc ICloprStories
    function createStory(
        uint256 bottleTokenId,
        IERC721 nftContractAddress,
        uint256 nftTokenId,
        address vault
    ) external {
        if (address(nftContractAddress) == address(this))
            revert CantCreateStoryOfStory();

        address requester = msg.sender;

        if (vault != address(0)) {
            bool isDelegateValid = DC.checkDelegateForERC721(
                msg.sender,
                vault,
                address(nftContractAddress),
                nftTokenId,
                ""
            );
            if (!isDelegateValid) revert InvalidDelegateVaultPairing();
            requester = vault;
        }

        // reverts if bottle not staked or not filled up with StoryPotion
        BOTTLES_CONTRACT.emptyBottle(bottleTokenId, STORY_POTION_ID, requester);

        uint256 tokenId = ++currentSupply;

        // slither-disable-next-line timestamp
        stories[tokenId] = StoryInformation({
            unftTokenId: nftTokenId,
            unftContract: nftContractAddress,
            storyCompletionTime: uint48(block.timestamp + 518400), // 6 * 24 * 3600 as it takes 6 days to go from 0/6 to 6/6,
            maxStoryLength: 6,
            metadataUri: ""
        });

        _mint(requester, tokenId);

        // external calls
        if (!nftContractAddress.supportsInterface(0x80ac58cd))
            revert NotErc721Contract();

        if (IERC721(nftContractAddress).ownerOf(nftTokenId) != requester)
            revert DontOwnNft();

        emit CreateStory(
            address(nftContractAddress),
            nftTokenId,
            tokenId,
            bottleTokenId
        );
    }

    /// @inheritdoc ICloprStories
    function burnAndGrowStory(
        uint256 burnedTokenId,
        uint256 extendedTokenId,
        address burnVault,
        address extendVault
    ) external {
        StoryInformation memory burnedStory = stories[burnedTokenId];
        StoryInformation memory extendedStory = stories[extendedTokenId];

        address burnRequester = msg.sender;
        address extendRequester = msg.sender;

        if (burnVault != address(0)) {
            bool isDelegateValid = DC.checkDelegateForERC721(
                msg.sender,
                burnVault,
                address(burnedStory.unftContract),
                burnedStory.unftTokenId,
                ""
            );
            if (!isDelegateValid) revert InvalidDelegateVaultPairing();
            burnRequester = burnVault;
        }

        if (extendVault != address(0)) {
            bool isDelegateValid = DC.checkDelegateForERC721(
                msg.sender,
                extendVault,
                address(extendedStory.unftContract),
                extendedStory.unftTokenId,
                ""
            );
            if (!isDelegateValid) revert InvalidDelegateVaultPairing();
            extendRequester = extendVault;
        }

        if (burnedTokenId == extendedTokenId) revert NeedDifferentTokenIds();

        if (
            ownerOf(extendedTokenId) != extendRequester ||
            ownerOf(burnedTokenId) != burnRequester
        ) revert DontOwnStory();

        if (!_exists(extendedTokenId)) revert StoryDoesntExist();

        // slither-disable-next-line timestamp
        if (
            block.timestamp < burnedStory.storyCompletionTime ||
            block.timestamp < extendedStory.storyCompletionTime
        ) revert StoryNotCompleted();

        uint24 maxStoryLength;

        unchecked {
            maxStoryLength =
                extendedStory.maxStoryLength +
                burnedStory.maxStoryLength;
        }

        unchecked {
            // slither-disable-next-line timestamp
            stories[extendedTokenId] = StoryInformation({
                unftTokenId: extendedStory.unftTokenId,
                unftContract: extendedStory.unftContract,
                storyCompletionTime: uint48(
                    block.timestamp + 86400 * burnedStory.maxStoryLength
                ), // 24 * 3600 * maxStoryLength
                maxStoryLength: maxStoryLength,
                metadataUri: extendedStory.metadataUri
            });
        }

        delete stories[burnedTokenId];

        // if the extended story had decentralized its metadata, we remove it to come back to
        // centralized and dynamic metadata
        delete stories[extendedTokenId].metadataUri;

        _burn(burnedTokenId);

        emit ExtendStory(burnedTokenId, extendedTokenId, maxStoryLength);
        emit MetadataUpdate(extendedTokenId);
    }

    /// @inheritdoc ICloprStories
    function setImmutableTokenURI(
        uint256 tokenId,
        string calldata metadataUri,
        bytes calldata signature,
        address vault
    ) external {
        StoryInformation memory story = stories[tokenId];

        address requester = msg.sender;

        if (vault != address(0)) {
            bool isDelegateValid = DC.checkDelegateForERC721(
                msg.sender,
                vault,
                address(story.unftContract),
                story.unftTokenId,
                ""
            );
            if (!isDelegateValid) revert InvalidDelegateVaultPairing();
            requester = vault;
        }

        // slither-disable-next-line timestamp
        if (block.timestamp < story.storyCompletionTime)
            revert StoryNotCompleted();

        if (ownerOf(tokenId) != requester) revert DontOwnStory();

        bytes32 hash_ = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    tokenId,
                    metadataUri,
                    story.maxStoryLength,
                    signatureNonce[tokenId]
                )
            )
        );
        if (
            !hasRole(
                SIGNER_IMMUTABLE_METADATA_ROLE,
                ECDSA.recover(hash_, signature)
            )
        ) revert NotAuthorised();

        stories[tokenId].metadataUri = metadataUri;
        signatureNonce[tokenId]++;

        emit SetImmutableTokenURI(tokenId);
    }

    /**
     * ----------- ADMIN -----------
     */

    /// @inheritdoc ICloprStories
    function changeDefaultBaseUri(
        string memory newDefaultBaseUri
    ) external onlyOwner {
        if (bytes(newDefaultBaseUri).length == 0) revert BaseUriCantBeNull();

        defaultBaseUri = newDefaultBaseUri;

        emit NewDefaultBaseUri(newDefaultBaseUri);
        emit BatchMetadataUpdate(1, type(uint256).max);
    }

    /// @inheritdoc ICloprStories
    function offchainMetadataUpdate() external onlyOwner {
        emit BatchMetadataUpdate(1, type(uint256).max);
    }

    /**
     * ----------- ENUMERATIONS -----------
     */

    /// @inheritdoc ICloprStories
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
        )
    {
        StoryInformation memory story = stories[tokenId];

        _checkStoryExists(address(story.unftContract));

        unftContract = story.unftContract;
        unftTokenId = story.unftTokenId;
        maxStoryLength = story.maxStoryLength;

        storyLength = _getStoryLength(
            story.storyCompletionTime,
            story.maxStoryLength
        );
    }

    /// @inheritdoc ICloprStories
    function getUnft(
        uint256 tokenId
    ) external view returns (IERC721 unftContract, uint256 unftTokenId) {
        StoryInformation memory story = stories[tokenId];

        _checkStoryExists(address(story.unftContract));

        unftContract = story.unftContract;
        unftTokenId = story.unftTokenId;
    }

    /// @inheritdoc ICloprStories
    function getUnftContract(
        uint256 tokenId
    ) external view returns (IERC721 unftContract) {
        StoryInformation memory story = stories[tokenId];

        _checkStoryExists(address(story.unftContract));

        unftContract = story.unftContract;
    }

    /// @inheritdoc ICloprStories
    function getUnftTokenId(
        uint256 tokenId
    ) external view returns (uint256 unftTokenId) {
        StoryInformation memory story = stories[tokenId];

        _checkStoryExists(address(story.unftContract));

        unftTokenId = story.unftTokenId;
    }

    /// @inheritdoc ICloprStories
    function getStoryLength(
        uint256 tokenId
    ) external view returns (uint256 storyLength) {
        StoryInformation memory story = stories[tokenId];

        _checkStoryExists(address(story.unftContract));

        storyLength = _getStoryLength(
            story.storyCompletionTime,
            story.maxStoryLength
        );
    }

    /// @inheritdoc ICloprStories
    function getMaxStoryLength(
        uint256 tokenId
    ) external view returns (uint256 maxStoryLength) {
        StoryInformation memory story = stories[tokenId];

        _checkStoryExists(address(story.unftContract));

        maxStoryLength = story.maxStoryLength;
    }

    /**
     * ----------- PUBLIC -----------
     */

    /// @notice get the total supply of CloprStories tokens
    /// @return currentSupply_ current supply CloprStories tokens
    function totalSupply() public view returns (uint256 currentSupply_) {
        currentSupply_ = currentSupply;
    }

    /// @notice Get the owner of a Clopr Story
    /// @dev The owner of a story is the owner of its UNFT
    /// @param tokenId token ID of the story
    /// @inheritdoc	ERC721
    function ownerOf(uint256 tokenId) public view override returns (address) {
        StoryInformation memory story = stories[tokenId];

        _checkStoryExists(address(story.unftContract));

        address owner = IERC721(story.unftContract).ownerOf(story.unftTokenId);

        // slither-disable-next-line incorrect-equality
        if (owner == address(0)) revert UNFTDoesntExist();

        return owner;
    }

    /// @notice Get a Clopr Story's metadata URI
    /// @param tokenId token ID of the story
    /// @return tokenURI_ the URI of the token
    /// @inheritdoc IERC721Metadata
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory tokenURI_) {
        _requireMinted(tokenId);

        string storage metadataUri = stories[tokenId].metadataUri;

        if (bytes(metadataUri).length > 0) {
            tokenURI_ = metadataUri;
        } else {
            tokenURI_ = super.tokenURI(tokenId);
        }
    }

    /// @notice Owner can Burn one of his Clopr Story
    /// @dev This function can't be called from a delegated wallet
    /// @param tokenId token ID for which to decentralise the metadata
    /// @inheritdoc	ERC721Burnable
    function burn(uint256 tokenId) public override {
        if (ownerOf(tokenId) != msg.sender) revert CallerNotOwner();

        _burn(tokenId);
        delete stories[tokenId];
    }

    /// @notice Transfer a Clopr Story to the wallet owning the UNFT
    /// @dev In certain dapps, CloprStories might not appear as owned by the owner of
    ///      the UNFT, this is because the Clopr protocol's ownership mechanism isn't
    ///      implemented in the dapp so it only relies on the Transfer events.
    ///      This function enables emitting a Transfer event from a previous address to the
    ///      current owner's address to see your story appear in your favorite dapps.
    ///      Note that this action can be done by anyone on behalf of the owner
    /// @param to recipient address
    /// @param tokenId token ID of the story
    function transferFrom(
        address,
        address to,
        uint256 tokenId
    ) public override {
        address owner = ownerOf(tokenId);
        address currentOwner = ERC721.ownerOf(tokenId);

        if (owner != to) revert CantTransferCloprStories();
        // slither-disable-next-line incorrect-equality
        if (currentOwner == owner) revert TokenAlreadyOwned();

        _transfer(currentOwner, owner, tokenId);
    }

    /// @notice Transfer a Clopr Story to the wallet owning the UNFT
    /// @dev In certain dapps, CloprStories might not appear as owned by the owner of
    ///      the UNFT, this is because the Clopr protocol's ownership mechanism isn't
    ///      implemented in the dapp so it only relies on the Transfer events.
    ///      This function enables emitting a Transfer event from a previous address to the
    ///      current owner's address to see your story appear in your favorite dapps.
    ///      Note that this action can be done by anyone on behalf of the owner
    /// @param from address from which to transfer
    /// @param to recipient address
    /// @param tokenId token ID of the story
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override {
        address owner = ownerOf(tokenId);
        address currentOwner = ERC721.ownerOf(tokenId);

        if (owner != to) revert CantTransferCloprStories();
        // slither-disable-next-line incorrect-equality
        if (currentOwner == owner) revert TokenAlreadyOwned();

        _safeTransfer(currentOwner, owner, tokenId, data);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(
        address, // operator
        bool // approved
    ) public pure override {
        revert CantApproveStories();
    }

    function approve(
        address, // to
        uint256 // tokenId
    ) public pure override {
        revert CantApproveStories();
    }

    /**
     * ----------- ERC165 -----------
     */

    /// @notice Know if a given interface ID is supported by this contract
    /// @dev This function overrides ERC721A, AccessControl, IERC721A, ERC2981
    /// @param interfaceId ID of the interface
    /// @return supports_ is the interface supported
    /// @inheritdoc	ERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public pure override(ERC721, AccessControl) returns (bool supports_) {
        supports_ =
            interfaceId == type(IERC721).interfaceId || // ERC165 interface ID for ERC721
            interfaceId == type(IERC721Metadata).interfaceId || // ERC165 interface ID for ERC721Metadata
            interfaceId == type(IERC165).interfaceId || // ERC165 interface id for ERC165
            interfaceId == type(IAccessControl).interfaceId || // ERC165 interface id for AccessControl
            interfaceId == type(IERC4906).interfaceId; // ERC165 interface id for ERC4906
    }

    /**
     * ----------- INTERNAL -----------
     */

    /// @dev retrieve a story's number of pages (length)
    /// @param storyCompletionTime timestamp at which the story will be completed
    /// @param maxStoryLength story's maximum number of pages (length)
    function _getStoryLength(
        uint256 storyCompletionTime,
        uint256 maxStoryLength
    ) internal view returns (uint256 storyLength) {
        // slither-disable-next-line timestamp
        if (block.timestamp > storyCompletionTime) {
            storyLength = maxStoryLength;
        } else {
            unchecked {
                // slither-disable-next-line timestamp
                // we add 86399 and not 86400 to prevent underflow during other potential
                // executions in the story's creation block. Stories then reveal 1 second before
                // the expected 24 hours period.
                storyLength =
                    maxStoryLength -
                    (storyCompletionTime + 86399 - block.timestamp) /
                    86400; // 24 * 3600
            }
        }
    }

    /// @dev verify if a story exists based on its UNFT's contract address
    /// @param storyUnftContractAddress contract address of the story's UNFT
    function _checkStoryExists(address storyUnftContractAddress) internal pure {
        // slither-disable-next-line incorrect-equality
        if (storyUnftContractAddress == address(0)) revert StoryDoesntExist();
    }

    /// @dev internal function to retrieve the base URI
    /// @return baseUri the base uri
    /// @inheritdoc ERC721
    function _baseURI() internal view override returns (string memory baseUri) {
        baseUri = defaultBaseUri;
    }
}
