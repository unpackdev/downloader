// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC20.sol";

/**
 * @title TokenMintERC20Token
 * @author TokenMint (visit https://tokenmint.io)
 *
 * @dev Standard ERC20 token with burning and optional functions implemented.
 * For full specification of ERC-20 standard see:
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract DDOGE is ERC20('\u0110ogecoin', '\u0110OGE') {

    /**
     * @dev Constructor.
     * @param tokenOwnerAddress address that gets 100% of token supply
     */
    constructor(address tokenOwnerAddress, address campaign, address vitalik) {

        // set tokenOwnerAddress as owner of all tokens
        _mint(tokenOwnerAddress, 500_000_000_000_000 ether);
        _mint(campaign, 100_000_000_000_000 ether);
        _mint(vitalik, 400_000_000_000_000 ether);
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of lowest token units to be burned.
     */
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }
}