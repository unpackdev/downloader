pragma solidity ^0.5.16;

import "./ERC20Detailed.sol";
import "./ERC20Mintable.sol";

contract GZKS is ERC20Detailed, ERC20Mintable {
    constructor(uint256 initialBalance) ERC20Detailed("ZKS Governance v1", "gZKS", 18) public {
        _mint(msg.sender, initialBalance);
    }
}