// contracts/PlayItForward.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// Import ERC20Burnable from the OpenZeppelin Contracts library
import "./ERC20Burnable.sol";

string constant _name = "PlayItForward";
string constant _symbol = "PFWD";
uint256 constant _maxTokens = 1000000; // unit = ether
uint256 constant _maxSupply = _maxTokens * 10 ** 18; // unit = wei

/**
 * @dev {PlayItForward} token, including:
 *
 *  - Mint a fixed supply of 1,00,000,000 tokens on creation (deflationary mechanism)
 *  - Disable future governance by limiting access control mechanism (no minting/pausing)
 *  - Enable the ability for holders to burn (aka destroy) their tokens
 *  - Enable the ability for holders to transfer tokens to other accounts
 *
 *  - Info: https://playitforward.io
 */
contract PlayItForward is ERC20Burnable {
    /**
     * @dev Mints `fixedSupply` amount of token and transfers them to `owner`.
     *
     * See {ERC20-constructor}.
     */
    constructor() ERC20(_name, _symbol) {
        _mint(msg.sender, _maxSupply);
    }
}
