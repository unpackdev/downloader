// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./BaseUpgradeable.sol";
import "./Constants.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable, BaseUpgradeable {
    using StringsUpgradeable for *;

    string internal _baseUri;

    function __ERC721URIStorage_init(string calldata baseUri_) internal onlyInitializing {
        __ERC721URIStorage_init_unchained(baseUri_);
    }

    function __ERC721URIStorage_init_unchained(string calldata baseUri_) internal onlyInitializing {
        _setBaseURI(baseUri_);
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseUri = _baseUri;

        return
            bytes(baseUri).length > 0
                ? string(abi.encodePacked(baseUri, "/", address(this).toHexString(), "/", tokenId.toString()))
                : "";
    }

    function setBaseTokenURI(string calldata baseTokenURI_) external onlyRole(OPERATOR_ROLE) {
        _setBaseURI(baseTokenURI_);
    }

    function _setBaseURI(string calldata baseUri_) internal virtual {
        _baseUri = baseUri_;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
