// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC721Enumerable.sol";
import "./Counters.sol";

contract OprimizedEnumNonBurnable is IERC721Enumerable, ERC721 {

    uint public _tokenIdCounter;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_){}

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId ||
               interfaceId == type(IERC165).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function getCurrentId() internal view returns (uint){
        return _tokenIdCounter;
    }

    function incrementCurrentId() internal {
        _tokenIdCounter++;
    }

    /**
     * Foreach all minted tokens until reached appropriate index
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < balanceOf(owner), "Owner index out of bounds");

        uint256 numMinted = getCurrentId();
        uint256 tokenIdsIdx;

        // Counter overflow is impossible as the loop breaks when uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i = 0; i < numMinted; i++) {

                if (_exists(i) && (ownerOf(i) == owner) ){

                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx = tokenIdsIdx + 1;
                }
            }
        }

        // Execution should never reach this point.
        assert(false);
        // added to stop compiler warnings
        return 0;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return getCurrentId();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        uint256 numMintedSoFar = getCurrentId();

        require(index < totalSupply(), "Index out of bounds");

        uint256 tokenIdsIdx;

        // Counter overflow is impossible as the loop breaks when uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i = 0; i < numMintedSoFar; i++) {
                if (_exists(i)){
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        // Execution should never reach this point.
        assert(false);
        return 0;
    }
}