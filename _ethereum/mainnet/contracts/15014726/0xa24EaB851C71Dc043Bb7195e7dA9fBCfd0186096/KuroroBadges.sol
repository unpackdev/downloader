// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";

/// @custom:security-contact otium@kurorobeasts.com
contract KuroroBadges is
ERC1155,
AccessControl,
Pausable,
ERC1155Burnable,
ERC1155Supply
{
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address admin, string memory baseUri)
    ERC1155(baseUri)
    {
        // Burner have admin role that will renounce on deploy script after giving the minter role to the minting
        // contract
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Giving roles to admin
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(URI_SETTER_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
    }

    function mintAccountsBatch(
        address[] memory account,
        uint256[] memory id,
        uint256[] memory amount,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        require( account.length == id.length && account.length == amount.length, "accounts, id and amount must have the same length");
        for(uint i = 0; i < account.length; i++) {
            _mint(account[i], id[i], amount[i], data);
        }
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}