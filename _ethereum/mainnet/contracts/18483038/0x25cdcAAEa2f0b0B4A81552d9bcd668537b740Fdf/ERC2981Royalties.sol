// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC165.sol";
import "./IERC2981Royalties.sol";

abstract contract ERC2981Royalties is ERC165, IERC2981Royalties {
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    /// @inheritdoc ERC165
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