pragma solidity ^0.5.0;

import "./ERC20Mintable.sol";


contract DoughMock is ERC20Mintable {
    constructor() public {
        ERC20Mintable.initialize(msg.sender);
    }
}
