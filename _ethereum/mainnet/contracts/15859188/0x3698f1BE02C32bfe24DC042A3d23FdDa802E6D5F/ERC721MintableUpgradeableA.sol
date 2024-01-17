// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./OwnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./IERC721MintableUpgradeable.sol";

abstract contract ERC721MintableUpgradeableA is
    ERC721EnumerableUpgradeable,
    IERC721MintableUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant OPERATOR = keccak256("OPERATOR");

    function addOperator(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(OPERATOR, account);
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR, msg.sender), "Must be operator");
        _;
    }

    function exists(uint256 tokenId) public view override returns (bool) {
        return super._exists(tokenId);
    }

    function mint(address to, uint256 tokenId)
        public
        virtual
        override
        onlyOperator
    {
        super._mint(to, tokenId);
    }

    function bulkMint(address[] memory _tos, uint256[] memory _tokenIds)
        public
        onlyOperator
    {
        require(_tos.length == _tokenIds.length);
        uint8 i;
        for (i = 0; i < _tos.length; i++) {
            mint(_tos[i], _tokenIds[i]);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
