// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./ERC721AUpgradeable.sol";
import "./ERC721AQueryableUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Referenced @openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol
 */
abstract contract ERC721ARoyalty is Initializable, ERC2981Upgradeable, ERC721AQueryableUpgradeable  {
    function __Royalty_init() internal onlyInitializing {
    }

    function __Royalty_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AUpgradeable, IERC721AUpgradeable, ERC2981Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId)
         || type(IERC2981Upgradeable).interfaceId == interfaceId
         || type(IERC721AUpgradeable).interfaceId == interfaceId;
    }

    /**
     * @dev See {ERC721A-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }
}
