// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./Bytes.sol";

/// @title Stardust ImmutableX ERC-1155 Token Contract
/// @author Brian Watroba, Daniel Reed
/// @dev Base ERC-721 built from Open Zeppellin standard with ImmutableX mintFor() functionality
/// @custom:security-contact clinder@stardust.gg
contract ERC721Stardust is Initializable, IERC721MetadataUpgradeable, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    address public imx;
    string private _uri;
    mapping(uint256 => bytes) public blueprints;

    event AssetMinted(address to, uint256 id, bytes blueprint);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _name, string memory _symbol, string memory _uriStr, address _imx) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        __UUPSUpgradeable_init();
        imx = _imx;
        _uri = _uriStr;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal override view virtual returns (string memory) {
        return _uri;
    }


    /// @notice Set new base URI for token metadata
    /// @param newuri New desired base URI
    function setURI(string memory newuri) public onlyOwner {
        _uri = newuri;
    }

    /// @notice Set the associated ImmutableX contract address that can call mintFor()
    /// @dev Initial address is set at deployment. This function allows for future updating
    /// @param _imx New desired ImmutableX contract address
    function setImx(address _imx) public onlyOwner {
        imx = _imx;
    }

    /// @notice Mints token type `id` to address `account`. Only callable by contract owner
    /// @dev Minting will primarility occur through the mintFor() function via ImmutableX
    /// @param account Account address to mint to
    /// @param id Token ID to mint
    function mint(address account, uint256 id) public onlyOwner {
        _mint(account, id);
    }

    /// @notice Mints `quantity` of token type `id` to address `user`. Only callable by ImmutableX
    /// @dev Required function, called by ImmutableX directly for minting/withdrawals to L1.
    /// @param user Account address to mint to
    /// @param quantity Quantity of tokens to mint. Must be value of 1.
    /// @param mintingBlob Bytes containing tokenId and blueprint string. Format: {tokenId}:{templateId,gameId}
    function mintFor(
        address user,
        uint256 quantity,
        bytes calldata mintingBlob
    ) external {
        require(imx == _msgSender(), "UNAUTHORIZED_ONLY_IMX");
        require(quantity == 1, "Mintable: invalid quantity");
        (uint256 id, bytes memory blueprint) = Bytes.split(mintingBlob);
        _mint(user, id);
        blueprints[id] = blueprint;
        emit AssetMinted(user, id, blueprint);
    }

    /// @notice Burns token type `id`. Only callable by token owner, approved address, or contract owner
    /// @param id Token ID to burn
    function burn(uint256 id) public {
        address tokenOwner = ERC721Upgradeable.ownerOf(id);
        require(tokenOwner == _msgSender() || isApprovedForAll(tokenOwner, _msgSender()) || owner() == _msgSender(), "UNAUTHORIZED_ONLY_BURNER");
        _burn(id);
    }

    /// @notice Required override to include access restriction to upgrade mechanism. Only owner can upgrade.
    /// @param newImplementation address of new implementation contract
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
