// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./IUnikuraCollectibles.sol";
import "./UnikuraErrors.sol";

/**
 * @author The Unikura Team
 * @title {UnikuraCollectibles} is for creating and managing Phygital NFTs.
 */
contract UnikuraCollectibles is IUnikuraCollectibles, ERC721EnumerableUpgradeable, OwnableUpgradeable {
    string public baseURI;
    mapping(address => bool) public minters;
    mapping(address => bool) public burners;

    /**
     * @dev Restricts function access to addresses designated as minters.
     */
    modifier onlyMinter() {
        if (!minters[msg.sender]) {
            revert UnikuraErrors.NotMinter(msg.sender);
        }
        _;
    }

    /**
     * @dev Restricts function access to addresses designated as burners.
     */
    modifier onlyBurner() {
        if (!burners[msg.sender]) {
            revert UnikuraErrors.NotBurner(msg.sender);
        }
        _;
    }

    /**
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev initializer for deployment when using the upgradeability pattern.
     * @param name_ The name of the NFT collection.
     * @param symbol_ The symbol of the NFT collection.
     */
    function initialize(string memory name_, string memory symbol_) external override initializer {
        __ERC721_init(name_, symbol_);
        __Ownable_init();
    }

    /**
     * @dev See {IERC165Upgradeable-supportsInterface}.
     * @param interfaceId The identifier of the interface to check.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Updates the base URI for the NFT metadata.
     * @dev Can only be called by the contract owner. Used to set or update the URI where NFT metadata is stored.
     * @param baseURI_ The new base URI to set.
     */
    function setBaseURI(string calldata baseURI_) external override onlyOwner {
        if (bytes(baseURI_).length == 0) {
            revert UnikuraErrors.EmptyString();
        }
        string memory oldBaseURI = baseURI;
        baseURI = baseURI_;
        emit BaseURIChanged(oldBaseURI, baseURI_);
    }

    /**
     * @dev See {IERC721Metadata-_baseURI}.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Grants or revokes minter role to a specific address.
     * @dev Accessible only by the contract owner. This function updates the permission for an address to mint new NFTs.
     * @param account The address to update the minter role.
     * @param status True to grant the minter role, false to revoke it.
     */
    function updateMinterRole(address account, bool status) external override onlyOwner {
        if (account == address(0)) {
            revert UnikuraErrors.ZeroAddress();
        }
        minters[account] = status;
        emit LogUpdateMinter(account, status);
    }

    /**
     * @notice Grants or revokes burner role to a specific address.
     * @dev Accessible only by the contract owner. This function updates the permission for an address to burn existing NFTs.
     * @param account The address to update the burner role.
     * @param status True to grant the burner role, false to revoke it.
     */
    function updateBurnerRole(address account, bool status) external override onlyOwner {
        if (account == address(0)) {
            revert UnikuraErrors.ZeroAddress();
        }
        burners[account] = status;
        emit LogUpdateBurner(account, status);
    }

    /**
     * @notice Mints a new NFT to a given address with a specific tokenId.
     * @dev Requires minter role. Used to create a new token representing a physical asset.
     * @param to The address to which the NFT will be minted.
     * @param tokenId The unique identifier for the NFT to be minted.
     */
    function mint(address to, uint256 tokenId) external override onlyMinter {
        _safeMint(to, tokenId);
    }

    /**
     * @notice Burns an NFT with a specific tokenId.
     * @dev Requires burner role. Used to remove a token from circulation.
     * @param tokenId The unique identifier for the NFT to be burned.
     */
    function burn(uint256 tokenId) external override onlyBurner {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }

    /**
     * @notice Prevents the contract owner from renouncing ownership.
     * @dev Overrides the original renounceOwnership function to ensure that ownership cannot be renounced.
     */
    function renounceOwnership() public view override onlyOwner {
        revert UnikuraErrors.CannotRenounceOwnership();
    }
}
