pragma solidity 0.5.16;

import "./ERC20Mintable.sol";
import "./ERC20Burnable.sol";
import "./ERC20Detailed.sol";


/**
 * @title BridgeToken
 * @dev Mintable, ERC20Burnable, ERC20 compatible BankToken for use by BridgeBank
 **/

contract BridgeToken is ERC20Mintable, ERC20Burnable, ERC20Detailed {
    constructor(string memory _symbol)
        public
        ERC20Detailed(_symbol, _symbol, 18)
    {
        // Intentionally left blank
    }
}
