// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC1155.sol";
import "Context.sol";
import "Counters.sol";
import "ECDSA.sol";
import "Ownable.sol";
import "ERC2981PerTokenRoyalties.sol";


contract BCANFT1155Base is ERC1155, ERC2981PerTokenRoyalties {
    string public name;
    string public symbol;
    string private _uri;
    uint256 immutable maxSupply;
    uint256 private currentIndex = 0;

    constructor(string memory name_, string memory symbol_, uint256 maxSupply_, string memory uri_, RoyaltyInfo memory royaltyInfo) ERC1155(uri_) {
        name = name_;
        symbol = symbol_;
        _uri = uri_;
        maxSupply = maxSupply_;
        _setTokenRoyalty(royaltyInfo);
    }

    function mintTo(address to) internal virtual {
        currentIndex = currentIndex + 1;
        require(totalSupply() <= maxSupply, '"totalSupply exceed maxSupply!');
        _mint(to, currentIndex, 1, '');
    }

    function mintBatch(address to, uint256 amount) internal virtual {
        require(totalSupply() + amount <= maxSupply, '"totalSupply exceed maxSupply!');

        uint256[] memory ids = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);
        for (uint256 i = 0; i < amount; i++) {
            currentIndex = currentIndex + 1;
            ids[i] = currentIndex;
            amounts[i] = 1;
        }
        _mintBatch(to, ids, amounts, '');
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981Base) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function totalSupply() public view virtual returns (uint256) {
        return currentIndex;
    }
}
