// contracts/token/ERC721/sovereign/SovereignNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./ERC721Upgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ITokenCreator.sol";
import "./ERC2981Upgradeable.sol";

/**
 * @title LazySovereignNFT
 * @dev This contract implements an ERC721 compliant NFT (Non-Fungible Token) with lazy minting.
 */

contract LazySovereignNFT is
    OwnableUpgradeable,
    ERC165Upgradeable,
    ERC721Upgradeable,
    ITokenCreator,
    ERC721BurnableUpgradeable,
    ERC2981Upgradeable
{
    using SafeMathUpgradeable for uint256;
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /////////////////////////////////////////////////////////////////////////////
    // Structs
    /////////////////////////////////////////////////////////////////////////////
    struct MintConfig {
        uint256 numberOfTokens;
        string baseURI;
        bool lockedMetadata;
    }

    /////////////////////////////////////////////////////////////////////////////
    // Storage
    /////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////
    // Public
    //////////////////////////////////////////////
    // Disabled flag
    bool public disabled;

    // Maximum number of tokens that can be minted
    uint256 public maxTokens;

    //////////////////////////////////////////////
    // Private
    //////////////////////////////////////////////
    // Mapping from token ID to approved address
    mapping(uint256 => address) private tokenApprovals;

    // Mapping from addresses that can mint outside of the owner
    mapping(address => bool) private minterAddresses;

    // Counter to keep track of the current token id.
    CountersUpgradeable.Counter private tokenIdCounter;

    // Mint batches for batch minting
    MintConfig private mintConfig;

    /////////////////////////////////////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////////////////////////////////////
    // Emits when the contract is disabled.
    event ContractDisabled(address indexed user);

    // Emits when prepared for minting.
    event PrepareMint(uint256 indexed numberOfTokens, string baseURI);

    // Emits when metadata is locked.
    event MetadataLocked(string baseURI);

    // Emits when metadata is updated.
    event MetadataUpdated(string baseURI);

    /////////////////////////////////////////////////////////////////////////////
    // Init
    /////////////////////////////////////////////////////////////////////////////
    /**
     * @dev Contract initialization function.
     * @param _name The name of the NFT contract.
     * @param _symbol The symbol of the NFT contract.
     * @param _creator The address of the contract creator.
     * @param _maxTokens The maximum number of tokens that can be minted.
     */
    function init(
        string calldata _name,
        string calldata _symbol,
        address _creator,
        uint256 _maxTokens
    ) public initializer {
        require(_creator != address(0), "creator cannot be null address");
        _setDefaultRoyaltyPercentage(10);
        disabled = false;
        maxTokens = _maxTokens;

        __Ownable_init();
        __ERC721_init(_name, _symbol);
        __ERC165_init();
        __ERC2981__init();

        _setDefaultRoyaltyReceiver(_creator);

        super.transferOwnership(_creator);
    }

    /////////////////////////////////////////////////////////////////////////////
    // Modifiers
    /////////////////////////////////////////////////////////////////////////////
    /**
     * @dev Modifier to check if the contract is not disabled.
     */
    modifier ifNotDisabled() {
        require(!disabled, "Contract must not be disabled.");
        _;
    }

    /////////////////////////////////////////////////////////////////////////////
    // Write Functions
    /////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Set a minter for the contract
     * @param _minter address of the minter.
     * @param _isMinter bool of whether the address is a minter.
     */
    function setMinterApproval(
        address _minter,
        bool _isMinter
    ) public onlyOwner ifNotDisabled {
        minterAddresses[_minter] = _isMinter;
    }

    /**
     * @dev Prepare a minting batch with a specified base URI and number of tokens.
     * @param _baseURI The base URI for token metadata.
     * @param _numberOfTokens The number of tokens to prepare for minting.
     */
    function prepareMint(
        string calldata _baseURI,
        uint256 _numberOfTokens
    ) public onlyOwner ifNotDisabled {
        _prepareMint(_baseURI, _numberOfTokens);
    }

    /**
     * @dev Prepare a minting batch with a specified base URI and number of tokens, and assign a minter address.
     * @param _baseURI The base URI for token metadata.
     * @param _numberOfTokens The number of tokens to prepare for minting.
     * @param _minter The address of the minter.
     */
    function prepareMintWithMinter(
        string calldata _baseURI,
        uint256 _numberOfTokens,
        address _minter
    ) public onlyOwner ifNotDisabled {
        _prepareMint(_baseURI, _numberOfTokens);
        minterAddresses[_minter] = true;
    }

    /**
     * @dev Mint a new token to the specified receiver.
     * @param _receiver The address of the token receiver.
     * @return uint256 Token Id of the new token.
     */
    function mintTo(address _receiver) external ifNotDisabled returns (uint256) {
        require(
            msg.sender == owner() || minterAddresses[msg.sender],
            "lazyMint::only owner or approved minter can mint"
        );
        return _createToken(
            _receiver,
            getDefaultRoyaltyPercentage(),
            getDefaultRoyaltyReceiver()
        );
    }

    /**
     * @dev Delete a token with the given ID.
     * @param _tokenId The ID of the token to delete.
     */
    function deleteToken(uint256 _tokenId) public {
        require(
            ownerOf(_tokenId) == msg.sender,
            "Must be the owner of the token."
        );
        burn(_tokenId);
    }

    /**
     * @dev Disable the contract, preventing further minting.
     */
    function disableContract() public onlyOwner {
        disabled = true;
        emit ContractDisabled(msg.sender);
    }

    /**
     * @dev Set the default royalty receiver address.
     * @param _receiver The address of the default royalty receiver.
     */
    function setDefaultRoyaltyReceiver(address _receiver) external onlyOwner {
        _setDefaultRoyaltyReceiver(_receiver);
    }

    /**
     * @dev Set a specific royalty receiver address for a token.
     * @param _receiver The address of the royalty receiver.
     * @param _tokenId The ID of the token.
     */
    function setRoyaltyReceiverForToken(
        address _receiver,
        uint256 _tokenId
    ) external onlyOwner {
        royaltyReceivers[_tokenId] = _receiver;
    }

    /**
     * @dev Update the base URI.
     * @param _baseURI The new base URI.
     */
    function updateBaseURI(string calldata _baseURI) external onlyOwner {
        require(
            !mintConfig.lockedMetadata,
            "updateBaseURI::metadata is locked"
        );

        mintConfig.baseURI = _baseURI;
        emit MetadataUpdated(_baseURI);
    }

    /**
     * @dev Lock the metadata to prevent  further updates.
     */
    function lockBaseURI() external onlyOwner {
        emit MetadataLocked(mintConfig.baseURI);
        mintConfig.lockedMetadata = true;
    }

    /////////////////////////////////////////////////////////////////////////////
    // Read Functions
    /////////////////////////////////////////////////////////////////////////////
    /**
     * @dev Checks if the supplied address is approved for minting
     * @param _address The address of the minter.
     * @return bool, whether the address is approved for minting.
     */
    function isApprovedMinter(
        address _address
    ) public view  returns (bool) {
        return minterAddresses[_address];
    }

    /**
     * @dev Get the address of the token creator for a given token ID.
     * @param _tokenId The ID of the token.
     * @return address of the token creator.
     */
    function tokenCreator(
        uint256 _tokenId
    ) public view override returns (address payable) {
        return payable(owner());
    }

    /**
     * @dev Get the current minting configuration.
     * @return mintConfig the mint config.
     */
    function getMintConfig()
        public
        view
        returns (MintConfig memory)
    {
        return mintConfig;
    }

    /**
     * @dev Get the token URI for a specific token.
     * @param _tokenId The ID of the token.
     * @return The token's URI.
     */
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    mintConfig.baseURI,
                    "/",
                    _tokenId.toString(),
                    ".json"
                )
            );
    }

    /**
     * @dev Get the total supply of tokens in existence.
     * @return The total supply of tokens.
     */
    function totalSupply() public view virtual returns (uint256) {
        return tokenIdCounter.current();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC165Upgradeable, ERC2981Upgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(ITokenCreator).interfaceId ||
            ERC165Upgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId) ||
            ERC721Upgradeable.supportsInterface(interfaceId);
    }

    /////////////////////////////////////////////////////////////////////////////
    // Internal Functions
    /////////////////////////////////////////////////////////////////////////////
    /**
     * @dev Create a new token and assign it to the specified recipient.
     * @param _to The address of the token recipient.
     * @param _royaltyPercentage The royalty percentage for the token.
     * @param _royaltyReceiver The address of the royalty receiver for the token.
     * @return The ID of the newly created token.
     */
    function _createToken(
        address _to,
        uint256 _royaltyPercentage,
        address _royaltyReceiver
    ) internal returns (uint256) {
        tokenIdCounter.increment();
        uint256 tokenId = tokenIdCounter.current();
        require(tokenId <= maxTokens, "_createToken::exceeded maxTokens");
        _safeMint(_to, tokenId);
        _setRoyaltyPercentage(tokenId, _royaltyPercentage);
        _setRoyaltyReceiver(tokenId, _royaltyReceiver);
        return tokenId;
    }

    /**
     * @dev Prepare a minting batch with a specified base URI and number of tokens.
     * @param _baseURI The base URI for token metadata.
     * @param _numberOfTokens The number of tokens to prepare for minting.
     */
    function _prepareMint(
        string calldata _baseURI,
        uint256 _numberOfTokens
    ) internal {
        require(
            _numberOfTokens <= maxTokens,
            "_prepareMint::exceeded maxTokens"
        );
        require(
            tokenIdCounter.current() == 0,
            "_prepareMint::can only prepare mint with 0 tokens"
        );
        mintConfig = MintConfig(_numberOfTokens, _baseURI, false);
        emit PrepareMint(_numberOfTokens, _baseURI);
    }
}
