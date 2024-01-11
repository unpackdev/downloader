// SPDX-License-Identifier: Apache-2.0
// 2022 (C) SUPER MOON Contracts

pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./AccessControl.sol";
import "./ERC1155Burnable.sol";
import "./Ownable.sol";

contract InnovationAgencyLithuania is
    ERC1155,
    AccessControl,
    ERC1155Burnable,
    Ownable
{
    string public name;
    string public symbol;

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(URI_SETTER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
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

    function mintAndDistribute(
        address[] memory recipients,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        for (uint i = 0; i < recipients.length; i++) {
            _mint(recipients[i], id, amount, data);
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
