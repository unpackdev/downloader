// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";

contract FeeSplitExtensionMock {
    
    address public operator;

    function setOperator(address _operator) public {
        operator = _operator;
    }

    function accrueFeesAndDistribute(IERC20 _setToken) public {
        uint256 amount = _setToken.balanceOf(address(this));
        _setToken.transfer(operator, amount);      // 100% fee to operator
    }
}