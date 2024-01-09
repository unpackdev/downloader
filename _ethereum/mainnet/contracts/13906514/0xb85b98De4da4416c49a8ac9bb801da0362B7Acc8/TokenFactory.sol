// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./DepositToken.sol";


contract TokenFactory {

    address public operator;

    constructor(address _operator) {
        operator = _operator;
    }

    function CreateDepositToken(address _lptoken) external returns(address) {
        require(msg.sender == operator, "!authorized");

        DepositToken dtoken = new DepositToken(operator, _lptoken);
        return address(dtoken);
    }
}