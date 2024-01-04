pragma solidity 0.7.5;

import "./ERC20.sol";

/**
 * @dev InstaFuel token of ERC20 standard.
 *
 * name           : InstaFuel
 * symbol         : IFU
 * decimal        : 18
 * total supply   : 100,000,000 IFU
 */
contract InstaFuel is ERC20 {
    /**
     * @dev Initialize token with name, symbol, and mint supply.
     */
    constructor() public ERC20('InstaFuel', 'IFU') {
        _mint(msg.sender, 100000000 * 1e18);
    }
}
