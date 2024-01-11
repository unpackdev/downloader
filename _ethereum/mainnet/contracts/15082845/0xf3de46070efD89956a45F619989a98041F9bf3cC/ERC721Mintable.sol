// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./CountersUpgradeable.sol";

/// @title Expose mint function on the standard ERC721 contract.
/// @dev Creates a public mint function that wraps the _safeMint function that can only be called by the minter role.
/// @custom:documentation https://roofstock-onchain.gitbook.io/roofstock-ideas/v1/home-ownership-token-genesis#mintable
abstract contract ERC721Mintable is Initializable, ERC721Upgradeable, AccessControlUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function __ERC721Mintable_init()
        internal
        onlyInitializing
    {
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to)
        public
        onlyRole(MINTER_ROLE)
    {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
