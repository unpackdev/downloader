// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";

/**
 * @dev Implementation of {IERC721EnumerableUpgradeable} which is gas optimised.
 */
contract ERC721EnumerableUpgradeable is ERC721Upgradeable, IERC721EnumerableUpgradeable {
    uint256 private _totalSupply;

    /**
     * @dev Initializes the contract by setting a `name`, `symbol` and a `totalSupply` to the token collection.
     */
    function __ERC721Enumerable_init(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_
    ) internal onlyInitializing {
        __ERC721_init(name_, symbol_);
        __ERC721Enumerable_init_unchained(totalSupply_);
    }

    function __ERC721Enumerable_init_unchained(uint256 totalSupply_) internal onlyInitializing {
        _totalSupply = totalSupply_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        uint256 tokenIdsIdx;

        // Counter overflow is impossible as the loop breaks when uint256 i is equal to totalSupply().
        unchecked {
            for (uint256 i = 1; i <= totalSupply(); i++) {
                if (_exists(i) && ERC721Upgradeable.ownerOf(i) == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        revert("ERC721Enumerable: unable to get token of owner by index");
    }

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return index;
    }

    /**
     * @dev Returns the token IDs owned by `owner`.
     */
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = ERC721Upgradeable.balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);

        if (tokenCount == 0) return tokenIds;

        uint256 currentIndex;

        // Counter overflow is impossible as the loop breaks when uint256 i is equal to totalSupply().
        unchecked {
            for (uint256 i = 1; i <= totalSupply(); i++) {
                if (_exists(i) && ERC721Upgradeable.ownerOf(i) == owner) {
                    tokenIds[currentIndex] = i;
                    currentIndex++;
                }
            }
        }

        return tokenIds;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev _mint function with checks for tokenId
     */
    function _mint(address to, uint256 tokenId) internal virtual override {
        require(tokenId > 0 && tokenId <= _totalSupply, "Invalid token id");
        super._mint(to, tokenId);
    }
}
