pragma solidity 0.7.5;

import "./ERC20.sol";

/**
 * @dev FameFuel token of ERC20 standard.
 *
 * name           : FameFuel
 * symbol         : FFU
 * decimal        : 18
 * total supply   : 100,000,000 FFU
 */
contract FameFuel is ERC20 {
    /**
     * @dev Initialize token with name, symbol, and mint supply.
     */
    constructor() public ERC20('FameFuel', 'FFU') {
        _mint(msg.sender, 100000000 * 1e18);
    }
}
