pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Detailed.sol";
import "./Context.sol";

/**
 * @title XMiningToken
 * @dev ERC20 Token, where all tokens are pre-assigned to the creator.
 */
contract XMiningToken is Context, ERC20, ERC20Detailed, ERC20Burnable {
    /**
     * @dev Constructor that gives _msgSender() all of existing tokens.
     */
    constructor()  public ERC20Detailed('X Mining Token', 'XMT', 18) {
        _mint(_msgSender(), 1000000000 ether);
    }
}