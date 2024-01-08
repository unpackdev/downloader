// SPDX-License-Identifier: Apache-2.0
// 2021 (C) SUPER HOW Contracts: superhow.ART NFT factory v1.0 

pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./AccessControl.sol";
import "./ERC1155Burnable.sol";
import "./Ownable.sol";

import "./ERC2981PerTokenRoyalties.sol";

contract SuperhowArtFactory is
    ERC1155,
    AccessControl,
    ERC1155Burnable,
    ERC2981PerTokenRoyalties,
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


    /// @notice Mint amount token of type `id` account `account`
    /// @param account the recipient of the token
    /// @param id id of the token type to mint
    /// @param amount amount of the token type to mint
    /// @param royaltyRecipient the recipient for royalties (if royaltyValue > 0)
    /// @param royaltyValue the royalties asked for (EIP2981)
    function mintRoyalty(
        address account,
        uint256 id,
        uint256 amount,
        address royaltyRecipient,
        uint256 royaltyValue,
        bytes memory data
    ) external onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);

        if (royaltyValue > 0) {
            _setTokenRoyalty(id, royaltyRecipient, royaltyValue);
        }
    }

    /// @notice Mint amount token of type `id` account `account`
    /// @param account the recipient of the token
    /// @param id id of the token type to mint
    /// @param amount amount of the token type to mint
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981Base, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
