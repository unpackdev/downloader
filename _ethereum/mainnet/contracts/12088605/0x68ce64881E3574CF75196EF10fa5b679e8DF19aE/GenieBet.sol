pragma solidity 0.7.5;

import "./ERC20.sol";

/**
 * @dev GenieBet token of ERC20 standard.
 *
 * name           : GenieBet
 * symbol         : GNE
 * decimal        : 18
 * total supply   : 8,888 GNE
 */
contract GenieBet is ERC20 {
    /**
     * @dev Initialize token with name, symbol, and mint supply.
     */
    constructor() public ERC20('GenieBet', 'GNE') {
        _mint(msg.sender, 8888 * 1e18);
    }
}
