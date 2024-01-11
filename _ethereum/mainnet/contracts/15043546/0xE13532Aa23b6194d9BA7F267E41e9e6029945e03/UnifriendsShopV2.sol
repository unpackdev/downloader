// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.9;

import "./ERC1155Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC1155BurnableUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./Initializable.sol";
import "./IExternalItemSupport.sol";

contract UnifriendsShopV2 is
    Initializable,
    ERC1155Upgradeable,
    AccessControlUpgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155SupplyUpgradeable
{
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant EXTERNAL_CONTRACT_ROLE =
        keccak256("EXTERNAL_CONTRACT_ROLE");

    function initialize() public initializer {
        __ERC1155_init("");
        __AccessControl_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function name() external pure returns (string memory) {
        return "Unifriends Shop";
    }

    function symbol() external pure returns (string memory) {
        return "UNISHP";
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    /// @dev Allows an external contract w/ role to burn an item
    function burnItemForOwnerAddress(
        uint256 _typeId,
        uint256 _quantity,
        address _itemOwnerAddress
    ) external onlyRole(EXTERNAL_CONTRACT_ROLE) {
        _burn(_itemOwnerAddress, _typeId, _quantity);
    }

    /// @dev Allows an external contract w/ role to mint an item
    function mintItemToAddress(
        uint256 _typeId,
        uint256 _quantity,
        address _toAddress
    ) external onlyRole(EXTERNAL_CONTRACT_ROLE) {
        _mint(_toAddress, _typeId, _quantity, "");
    }

    /// @dev Allows a bulk transfer
    function bulkSafeTransfer(
        uint256 _typeId,
        uint256 _quantityPerRecipient,
        address[] calldata recipients
    ) external {
        for (uint256 i = 0; i < recipients.length; i++) {
            safeTransferFrom(
                _msgSender(),
                recipients[i],
                _typeId,
                _quantityPerRecipient,
                ""
            );
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IExternalItemSupport).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
