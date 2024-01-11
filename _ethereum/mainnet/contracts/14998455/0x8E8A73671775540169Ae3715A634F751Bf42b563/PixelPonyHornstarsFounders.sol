// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./AccessControl.sol";
import "./ERC1155.sol";
import "./Strings.sol";
import "./IExternalItemSupport.sol";

import "./console.sol";

contract PixelPonyHornstarsFounders is ERC1155, AccessControl {
    using Strings for uint256;

    string public baseURI;

    bytes32 private constant EXTERNAL_CONTRACT_ROLE =
        keccak256("EXTERNAL_CONTRACT_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");

    constructor() ERC1155("") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
        _setupRole(URI_SETTER_ROLE, _msgSender());
    }

    function name() external pure returns (string memory) {
        return "Pixel Pony Hornstars Founders";
    }

    function symbol() external pure returns (string memory) {
        return "PPHF";
    }

    /// @dev mint a single id and amount to sender
    function mint(uint256 _id, uint256 _amount) external onlyRole(OWNER_ROLE) {
        _mint(_msgSender(), _id, _amount, "");
    }

    /// @dev Batch mint to a single adress
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(OWNER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    /// @dev Mints to multiple addresses, specific id and amounts
    function mintToAddresses(
        address[] memory addresses,
        uint256 _typeId,
        uint256 _amount,
        bytes memory _data
    ) public onlyRole(OWNER_ROLE) {
        console.log("here", addresses[0]);
        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], _typeId, _amount, _data);
        }
    }

    /// @dev Sets the base uri for the collection
    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
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

    /// @dev Interface support w/ IExternalItemSupport
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IExternalItemSupport).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
