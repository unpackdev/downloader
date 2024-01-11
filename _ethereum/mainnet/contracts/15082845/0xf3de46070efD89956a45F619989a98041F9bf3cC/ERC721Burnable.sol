// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";

/// @title Expose burn function on the standard ERC721 contract.
/// @dev Creates a public burn function that wraps the _burn function that can only be called by the burner role.
/// @custom:documentation https://roofstock-onchain.gitbook.io/roofstock-ideas/v1/home-ownership-token-genesis#burnable
abstract contract ERC721Burnable is Initializable, ERC721Upgradeable, AccessControlUpgradeable {
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    function __ERC721Burnable_init()
        internal
        onlyInitializing
    {
        _grantRole(BURNER_ROLE, msg.sender);
    }

    function burn(uint256 tokenId)
        public
        virtual
        onlyRole(BURNER_ROLE)
    {
        _burn(tokenId);
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
