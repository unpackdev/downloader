// Used for testing

pragma solidity ^0.5.12;

import "./ERC20Detailed.sol";
import "./ERC20Capped.sol";

// We import this library to be able to use console.log
import "./console.sol";

// THIS IS A MOCK TEST CONTRACT - DO NOT AUDIT OR DEPLOY!
contract MockStakingToken is ERC20Detailed, ERC20Capped {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _amount
    )
        public
        ERC20Detailed(_name, _symbol, _decimals)
        ERC20Capped(_amount.mul(10**uint256(_decimals)))
    {
        _mint(msg.sender, cap());
    }
}
