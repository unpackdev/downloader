// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

/**
 * @dev An ERC20 implementation of the BuyzookaToken ecosystem token. All tokens are initially pre-assigned to
 * the creator, and can later be distributed freely using transfer transferFrom and other ERC20
 * functions.
 */
contract BuyzookaToken is ERC20, ERC20Burnable, Ownable {
    uint32 public constant VERSION = 8;

    uint8 private constant DECIMALS = 18;
    uint256 private constant TOKEN_WEI = 10 ** uint256(DECIMALS);

    uint256 private constant INITIAL_WHOLE_TOKENS = uint256((10 ** 8));
    uint256 private constant INITIAL_SUPPLY = uint256(INITIAL_WHOLE_TOKENS) * uint256(TOKEN_WEI);

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() ERC20("BuyzookaToken", "BZOO") {
        // This is the only place where we ever mint tokens.
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}
