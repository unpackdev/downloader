pragma solidity 0.6.6;

import "./ERC20CappedUpgradeable.sol";

contract EglToken is Initializable, ContextUpgradeable, ERC20CappedUpgradeable {
    function initialize(
        address initialRecipient, 
        string memory name, 
        string memory symbol, 
        uint256 initialSupply
    ) 
        public 
        initializer 
    {
        require(initialRecipient != address(0), "EGLTOKEN:INVALID_RECIPIENT");

        __ERC20_init(name, symbol);
        __ERC20Capped_init_unchained(initialSupply);

        _mint(initialRecipient, initialSupply);
    }
}
