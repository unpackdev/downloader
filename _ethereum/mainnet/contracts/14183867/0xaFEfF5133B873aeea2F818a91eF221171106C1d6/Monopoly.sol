//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.9;

import "./ERC20Votes.sol";

/**
 * @dev An ERC20 contract having 18 decimals and total fixed supply of
 * 1 Billion tokens.
 */
contract Monopoly is ERC20Votes {

    // CAP of total supply.
    uint256 public immutable CAP;

    // Private pre-sale address
    address public immutable privatePreSale;

    // Public pre-sale address
    address public immutable publicPreSale;

    // Marketing funds address.
    address public immutable marketing;

    // Development funds address.
    address public immutable development;

    // Locked funds address.
    address public immutable lockedLiquidity;

    address public immutable lockedCommunityTreasury;

    /// Initialises contract's state and mints 1 Billion tokens.
    constructor()
        ERC20Permit("Monopoly")
        ERC20("Monopoly", "MONOPOLY")
    {
        CAP = 1_000_000_000 * (10 ** decimals());

        privatePreSale = 0x78c513a267AbBA6C3Ce6453FEE65A50915E2Ce8e;
        publicPreSale = 0xaE2C4d893547c4158022B88e84BbcCC6C372A2Cb;
        marketing = 0xebbD376eaCB047A0A33DC71588852d3765a21C5c;
        development = 0x0B4fE30d67fFb7a576fEACBFB7a104Fad8d4278d;
        lockedLiquidity = 0x9194883B8a9577C607aCb2BC9dEc8826fd2beD19;
        lockedCommunityTreasury = 0x3b846507C39e5d532e1e82B94Fc5dAD0EECB8726;

        _mint(privatePreSale, CAP * 15 / 100);
        _mint(publicPreSale, CAP * 5 / 100);
        _mint(marketing, CAP * 20 / 100);
        _mint(development, CAP * 10 / 100);
        _mint(lockedLiquidity, CAP * 15 / 100);
        _mint(lockedCommunityTreasury, CAP * 35 / 100);

        assert(totalSupply() == CAP);
    }
}
