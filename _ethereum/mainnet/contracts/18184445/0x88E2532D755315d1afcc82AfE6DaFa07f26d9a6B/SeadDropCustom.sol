// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC721SeaDropUpgradeable.sol";


/*
 * @notice ERC721SeaDropUpgradeable
 *         + multiDrop for owner
 */
contract SeaDropCustom is ERC721SeaDropUpgradeable {

    struct Mint {
        address to;
        uint quantity;
    }

    /**
     * @notice Initialize the token contract with its name, symbol and allowed SeaDrop addresses.
     */
    function initialize(
        string memory name,
        string memory symbol,
        address[] memory allowedSeaDrop
    ) external initializer initializerERC721A {
        ERC721SeaDropUpgradeable.__ERC721SeaDrop_init(
            name,
            symbol,
            allowedSeaDrop
        );
    }

    // like mintSeadDrop but for owner
    function safeMint(address to, uint256 quantity)
        internal
        virtual
        onlyOwner
        nonReentrant
    {
        if (_totalMinted() + quantity > maxSupply()) {
            revert MintQuantityExceedsMaxSupply(
                _totalMinted() + quantity,
                maxSupply()
            );
        }
        _safeMint(to, quantity);
    }

    function multiMint(Mint[] memory mints) public onlyOwner {
        for (uint i = 0; i < mints.length; i++) {
            safeMint(mints[i].to, mints[i].quantity);
        }
    }
}
