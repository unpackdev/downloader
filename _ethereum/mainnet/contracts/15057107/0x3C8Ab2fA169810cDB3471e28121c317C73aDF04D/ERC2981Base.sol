// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC165.sol";

import "./IERC2981Royalties.sol";

/// Thanks to https://github.com/dievardump/EIP2981-implementation
/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981Base is ERC165, IERC2981Royalties {
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}