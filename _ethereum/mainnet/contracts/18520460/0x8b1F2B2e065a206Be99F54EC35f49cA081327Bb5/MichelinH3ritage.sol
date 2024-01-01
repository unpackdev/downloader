
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./StringsUpgradeable.sol";

import "./ERC721Base.sol";
import "./ERC721MaxSupplyExtension.sol";
import "./ERC721CouponExtension.sol";

contract MichelinH3ritage is ERC721Base, ERC721MaxSupplyExtension, ERC721CouponExtension {

    function initialize(string calldata name, string calldata shortName, string calldata domain, address admin) public initializer {
        __ERC721Base_init(name, shortName, domain, admin);
        __ERC721MaxSupplyExtension_init(admin);
        __ERC721CouponExtension_init(admin);
    }

    function tokenURI(uint256 tokenId) public view override (ERC721Base, ERC721Upgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721Base, ERC721MaxSupplyExtension, ERC721CouponExtension) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override (ERC721Base, ERC721Upgradeable) returns (string memory) {
        return super._baseURI();
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override (ERC721Base, ERC721EnumerableUpgradeable, ERC721MaxSupplyExtension) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _beforeTokenMint(address to, uint256 firstTokenId, uint256 batchSize) internal virtual override (ERC721BetterHooksUpgradeable, ERC721MaxSupplyExtension) {
        super._beforeTokenMint(to, firstTokenId, batchSize);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[10] private __gap;

}
