// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./SafeMath.sol";

contract SuperDogeRookieCard is Ownable, ERC721 {
    using SafeMath for uint256;

    uint256 public maxRookieCards = 125;
    string public baseTokenURI =
        "ipfs://QmRfcLpP5xNDCwJ7znR1g3DjaZ9FjqG5jpryBryCJrFgQf/";
    uint256 public supply = 0;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    /**
     * @dev Mints n rookie cards to deployer for airdrops.
     * @dev Can only be called by owner.
     */
    function mintRookieCards(uint256 numCards) public onlyOwner {
        require(
            numCards.add(supply) <= maxRookieCards,
            "SuperDogeRookieCard: Number minted would exceed max supply."
        );
        for (uint256 i = 0; i < numCards; i++) {
            mintRookieCard();
        }
    }

    /**
     * @dev Private function for minting a single rookie card.
     */
    function mintRookieCard() private {
        _safeMint(_msgSender(), supply);
        supply = supply.add(1);
    }

    /**
     * @dev Returns the base token URI.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @param newBaseURI base token URI
     * @dev Sets the new base token URI.
     * @dev Can only be called by owner.
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseTokenURI = newBaseURI;
    }

    /**
     * @param cap New maximum rookie card cap
     * @dev Sets the maximum number of rookie cards.
     * @dev Can only be called by owner.
     */
    function setMaxCap(uint256 cap) public onlyOwner {
        require(
            cap >= supply,
            "SuperDogeRookieCard: New max cap must be greater than or equal to current supply."
        );

        maxRookieCards = cap;
    }
}
