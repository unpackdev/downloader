
pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

/**
 * @title PFANToken
 * @dev Very simple ERC20 Token, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract PFANToken is ERC20, ERC20Detailed {

    uint8 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 50000000000 * (10 ** uint256(DECIMALS));

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("PowerFan", "PFAN", DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}