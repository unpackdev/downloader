// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./ERC1155Upgradeable.sol";
import "./Strings.sol";

abstract contract ERC1155URIStorageUpgradeable is ERC1155Upgradeable {
    string internal _baseURI;
    string public name;
    string public symbol;

    function __ERC1155URIStorageUpgradeable_init(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        name = name_;
        symbol = symbol_;
        __ERC1155_init("");
    }

    function uri(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        string memory tokenURI = _getTokenURI(tokenId);
        return string(abi.encodePacked(_baseURI, tokenURI));
    }

    function _getTokenURI(
        uint256 tokenId
    ) internal pure returns (string memory) {
        return Strings.toString(tokenId);
    }

    function _setBaseURI(string memory baseURI) internal virtual {
        _baseURI = baseURI;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}
