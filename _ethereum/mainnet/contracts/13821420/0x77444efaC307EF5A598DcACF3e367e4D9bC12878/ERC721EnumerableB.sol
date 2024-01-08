// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721B.sol";
import "./IERC721Enumerable.sol";

/*************************
 * @author: Squeebo       *
 * @license: BSD-3-Clause *
 **************************/

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableB is ERC721B, IERC721Enumerable {    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721B)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256 tokenId)
    {
        require(
            index < this.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );

        uint256 count;
        uint256 length = _owners.length;
        for (uint256 i; i < length; ++i) {
            if (owner == _owners[i]) {
                if (count == index) {
                    delete count;
                    delete length;
                    return i;
                } else ++count;
            }
        }

        delete count;
        delete length;
        require(false, "ERC721Enumerable: owner index out of bounds");
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _owners.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < _owners.length,
            "ERC721Enumerable: global index out of bounds"
        );
        return index;
    }
}
