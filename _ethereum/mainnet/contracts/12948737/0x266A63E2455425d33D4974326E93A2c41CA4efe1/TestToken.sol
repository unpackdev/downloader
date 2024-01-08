pragma solidity 0.6.6;

import "./ERC20CappedUpgradeable.sol";

contract TestToken is Initializable, ContextUpgradeable, ERC20CappedUpgradeable {
    event Test(uint256 date);
    function initialize(
        address initialRecipient, 
        string memory name, 
        string memory symbol, 
        uint256 initialSupply
    ) 
        public 
        initializer 
    {
        require(initialRecipient != address(0), "TOKEN:INVALID_RECIPIENT");

        __ERC20_init(name, symbol);
        __ERC20Capped_init_unchained(initialSupply);

        _mint(initialRecipient, initialSupply);
        emit Test(block.timestamp);
    }
}
