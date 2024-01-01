// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC1155Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract EvelonNFTs is
    Initializable,
    ERC1155Upgradeable,
    AccessControlUpgradeable,
    ERC1155SupplyUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address defaultAdmin,
        address minter,
        address upgrader
    ) public initializer {
        __ERC1155_init(
            "https://api.evelon.app/api/metadata_nfts?collection_id=",
            "&dynamic=0"
        );
        __AccessControl_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
        _grantRole(UPGRADER_ROLE, upgrader);
        _grantRole(URI_SETTER_ROLE, defaultAdmin);
    }

    function setURI(
        string memory newuri,
        string memory newSuffix
    ) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri, newSuffix);
    }

    function mint(
        address account,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mint(account, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mintBatch(to, amounts, data);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    // The following functions are overrides required by Solidity.

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._update(from, to, ids, values);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
