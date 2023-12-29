pragma solidity 0.5.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Capped.sol";
import "./ERC20Detailed.sol";
import "./TokenTimelock.sol";


contract CustomToken is ERC20, ERC20Detailed, ERC20Capped, ERC20Burnable {
    constructor(
            string memory _name,
            string memory _symbol,
            uint8 _decimals,
            uint256 _maxSupply
        )
        ERC20Burnable()
        ERC20Capped(_maxSupply)
        ERC20Detailed(_name, _symbol, _decimals)
        ERC20()
        public {
            
        }
}
