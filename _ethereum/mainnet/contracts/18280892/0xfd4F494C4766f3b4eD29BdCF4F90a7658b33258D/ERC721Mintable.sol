// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title ERC721 Mintable
 * @author akibe
 */

import "./ERC721.sol";
import "./IERC721Mintable.sol";

abstract contract ERC721Mintable is IERC721Mintable, ERC721 {

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721Mintable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    function mint(address to, uint256 tokenId) public virtual {
        _safeMint(to, tokenId);
    }
}
