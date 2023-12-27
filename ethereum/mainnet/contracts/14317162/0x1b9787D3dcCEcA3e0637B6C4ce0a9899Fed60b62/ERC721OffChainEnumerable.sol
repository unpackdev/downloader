// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721.sol";

/**
 * @dev This adds enumerability of all the token ids in the contract as well as all token ids owned by each
 * account but rips out the core of the gas-wasting processing that comes from OpenZeppelin.
 */
abstract contract ERC721OffChainEnumerable is ERC721 {
    uint256 numBurned = 0;

    /**
     * @dev Similiar to {IERC721Enumerable-totalSupply}.
     */
    function totalTokens() public view virtual returns (uint256) {
        return _owners.length - numBurned;
    }

    /**
     * @dev Similar to {IERC721Enumerable-tokenByIndex}.
     */

    function getTokenByIndex(uint256 index) public view virtual returns (uint256) {
        require(index < totalTokens(), "ERC721OffChainEnumerable: global index out of bounds");
        uint256 count;

        // When a token is burned, the index of all tokens above that index
        // should be shifted by 1 to the left. Since we do not pop entries of _owners, we need
        // to add back the missing shift.
        for(uint i = 0; i < _owners.length; i++ ){
            if(_owners[i] == address(0)) count += 1;
            if(int(i) - int(count) == int(index)) return uint256(i) + 1;
        }
        require(false, "ERC721OffChainEnumerable: index not found");
    }

    /**
     * @dev Similiar to {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function getTokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256 tokenId) {
        require(index < balanceOf(owner), "ERC721OffChainEnumerable: owner index out of bounds");

        uint count;
        for(uint i; i < _owners.length; i++){
            if(owner == _owners[i]){
                if(count == index) return i + 1;
                else count++;
            }
        }

        revert("ERC721OffChainEnumerable: owner index out of bounds");
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if( to == address(0) ){
            numBurned++;
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}