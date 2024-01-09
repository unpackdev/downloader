// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ICROWDToken.sol";

contract CROWDToken is ICROWDToken {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _amount
    ) ERC20(_name, _symbol) {
        _mint(_msgSender(), _amount * 10**decimals());
    }

    //Don't accept ETH or BNB
    receive() external payable {
        revert("Don't accept ETH or BNB");
    }
}
