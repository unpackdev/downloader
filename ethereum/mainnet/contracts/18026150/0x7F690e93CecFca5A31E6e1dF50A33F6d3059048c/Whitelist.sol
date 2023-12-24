// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "./Whitelist.sol";

contract $Whitelist is Whitelist {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $_check(address _sponsor,address _account) external view returns (bool ret0) {
        (ret0) = super._check(_sponsor,_account);
    }

    function $_add(address _account) external {
        super._add(_account);
    }

    function $_addBatch(address[] calldata _accounts) external {
        super._addBatch(_accounts);
    }

    function $_remove(address _account) external {
        super._remove(_account);
    }

    function $_removeBatch(address[] calldata _accounts) external {
        super._removeBatch(_accounts);
    }

    receive() external payable {}
}
