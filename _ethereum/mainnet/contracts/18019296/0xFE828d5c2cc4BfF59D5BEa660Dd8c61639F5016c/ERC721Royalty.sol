// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./ERC721EnumerableUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Referenced @openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol
 */
abstract contract ERC721Royalty is Initializable, ERC2981Upgradeable, ERC721EnumerableUpgradeable  {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721EnumerableUpgradeable, ERC2981Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721A-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }
}
