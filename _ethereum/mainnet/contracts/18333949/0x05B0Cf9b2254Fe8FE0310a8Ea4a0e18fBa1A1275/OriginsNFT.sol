// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Openzeppelin
import "./Ownable2StepUpgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";
// Interfaces
import "./IOriginsNFT.sol";

// Errors
error InvalidTokenID();
error NotMarketManager();
error NotAllowedToMintNFTs();
error ZeroAddress();

/**
 * @title OriginsNFT
 * @dev Origins and Ancestry Series 1 Collection contract
 * @author Amberfi
 */
contract OriginsNFT is
    IOriginsNFT,
    Initializable,
    ERC721Upgradeable,
    ReentrancyGuardUpgradeable,
    Ownable2StepUpgradeable,
    PausableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    CountersUpgradeable.Counter private _tokenIdsCounter;
    address private _marketManager; // Market manager contract address

    string public baseURI; // Base URI of the collection

    // Events
    event MarketManagerChanged(
        address indexed previousContract,
        address indexed newContract
    ); // Event emitted when market manager changed
    event BaseURIChanged(string baseURI); // Event emitted when base URI changed

    /**
     * @dev Modifier to check if caller is market manager
     */
    modifier onlyMarketManager() {
        if (msg.sender != _marketManager) {
            revert NotMarketManager();
        }
        _;
    }

    /**
     * @dev Initializer
     * @param name_ (string calldata) Collection name
     * @param symbol_ (string calldata) Collection symbol
     * @param baseURI_ (string calldata) Collection base URI
     */
    function initialize(
        string calldata name_,
        string calldata symbol_,
        string calldata baseURI_
    ) public initializer {
        __Ownable2Step_init();
        __ERC721_init(name_, symbol_);
        _setBaseURI(baseURI_);

        // Starts from 1
        _tokenIdsCounter.increment();
    }

    /**
     * @dev Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Set MarketManager contract address
     * @param marketManager_ (address) Market Manager contract address
     */
    function setMarketManager(address marketManager_) external onlyOwner {
        if (marketManager_ == address(0)) {
            revert ZeroAddress();
        }

        address prev = _marketManager;
        _marketManager = marketManager_;

        emit MarketManagerChanged(prev, marketManager_);
    }

    /**
     * @dev Set the base URI
     * @param baseURI_ (string calldata) base URI
     */
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    /**
     * @dev Mint NFT with ID `tokenId_` (called by MarketManager)
     * @param to_ (address) Mint to address
     * @param tokenId_ (uint256) Token ID to mint
     */
    function mint(
        address to_,
        uint256 tokenId_
    ) external nonReentrant onlyMarketManager whenNotPaused {
        _safeMint(to_, tokenId_);

        _tokenIdsCounter.increment();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId_
    ) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId_);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * @param tokenId_ (uint256) Token ID
     * @return (string memory) URI of the token
     */
    function tokenURI(
        uint256 tokenId_
    ) public view override returns (string memory) {
        if (!_exists(tokenId_)) {
            revert InvalidTokenID();
        }

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId_.toString(), ".json")
                )
                : "";
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     * Emits a {Transfer} event.
     * @param tokenId_ (uint256) Token ID to burn
     */
    function _burn(uint256 tokenId_) internal override(ERC721Upgradeable) {
        super._burn(tokenId_);
    }

    /**
     * @dev Set the base URI
     * @param baseURI_ (string calldata) base URI
     */
    function _setBaseURI(string calldata baseURI_) private {
        baseURI = baseURI_;

        emit BaseURIChanged(baseURI_);
    }
}
