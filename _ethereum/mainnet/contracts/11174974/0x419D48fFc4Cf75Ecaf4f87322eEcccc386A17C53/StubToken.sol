pragma solidity 0.5.17;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

contract StubToken is ERC20, ERC20Detailed {
    constructor(string memory name, string memory symbol, uint256 initialSupply)
        public ERC20Detailed(name, symbol, 18) {
        _mint(msg.sender, initialSupply);
    }
}
