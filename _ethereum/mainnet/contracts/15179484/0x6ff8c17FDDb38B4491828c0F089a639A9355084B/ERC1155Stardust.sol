// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./Bytes.sol";

/// @title Stardust ImmutableX ERC-1155 Token Contract
/// @author Brian Watroba, Daniel Reed
/// @dev Base ERC-1155 built from Open Zeppellin standard with ImmutableX mintFor() functionality
/// @custom:security-contact clinder@stardust.gg
contract ERC1155Stardust is Initializable, ERC1155Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    address public imx;
    mapping(uint256 => bytes) public blueprints;

    event AssetMinted(address to, uint256 id, bytes blueprint);

    modifier onlyBurner(address account) {
      require(account == _msgSender() || isApprovedForAll(account, _msgSender()) || owner() == _msgSender(),
      "UNAUTHORIZED_ONLY_BURNER"
      );
      _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _uriStr, address _imx) public initializer {
        __ERC1155_init(_uriStr);
        __Ownable_init();
        __UUPSUpgradeable_init();
        imx = _imx;
    }

    /// @notice Set new base URI for token metadata
    /// @param newuri New desired base URI
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /// @notice Set the associated ImmutableX contract address that can call mintFor()
    /// @dev Initial address is set at deployment. This function allows for future updating
    /// @param _imx New desired ImmutableX contract address
    function setImx(address _imx) public onlyOwner {
        imx = _imx;
    }

    /// @notice Mints `quantity` of token type `id` to address `account`. Only callable by contract owner
    /// @dev Minting will primarility occur through the mintFor() function via ImmutableX
    /// @param account Account address to mint to
    /// @param id Token ID to mint
    /// @param amount Quantity of tokens to mint
    function mint(address account, uint256 id, uint256 amount)
        public
        onlyOwner
    {
        _mint(account, id, amount, "");
    }

    /// @notice Mints `quantities` of token types `ids` to address `to`. Only callable by contract owner
    /// @dev Minting will primarility occur through the mintFor() function via ImmutableX
    /// @param to Account address to mint to
    /// @param ids Token IDs to mint
    /// @param amounts Quantities of tokens to mint
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, "");
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
        _mint(user, id, quantity, "");
        blueprints[id] = blueprint;
        emit AssetMinted(user, id, blueprint);
    }

    /// @notice Burns `value` of token type `id` owned by address `account`. Only callable by token owner, approved address, or contract owner
    /// @param account Account owner whose tokens are desired to burn
    /// @param id Token ID to burn
    /// @param value Quantity of tokens to burn
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public onlyBurner(account) {
        _burn(account, id, value);
    }

    /// @notice Burns `values` of token types `ids` owned by address `account`. Only callable by token owner, approved address, or contract owner
    /// @param account Account owner whose tokens are desired to burn
    /// @param ids Token IDs to burn
    /// @param values Quantities of tokens to burn
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public onlyBurner(account) {
        _burnBatch(account, ids, values);
    }

    /// @notice Required override to include access restriction to upgrade mechanism. Only owner can upgrade.
    /// @param newImplementation address of new implementation contract
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
