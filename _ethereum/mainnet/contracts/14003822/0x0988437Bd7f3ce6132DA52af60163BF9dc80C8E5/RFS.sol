pragma solidity ^0.5.5;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

contract RFS is Context, ERC20, ERC20Detailed {
     /**
     * @dev Constructor that gives _msgSender() all of existing tokens.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) public ERC20Detailed(name, symbol, 18) {
        _mint(_msgSender(), initialSupply);
    }
}
