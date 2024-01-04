pragma solidity 0.7.5;

import "./ERC20.sol";

/**
 * @dev Mediconnect token of ERC20 standard.
 *
 * name           : Mediconnect
 * symbol         : MEDI
 * decimal        : 18
 * total supply   : 500,000,000 MEDI
 */
contract Mediconnect is ERC20 {
    /**
     * @dev Initialize token with name, symbol, and mint supply.
     */
    constructor() public ERC20('Mediconnect', 'MEDI') {
        _mint(msg.sender, 500000000 * 1e18);
    }
}
