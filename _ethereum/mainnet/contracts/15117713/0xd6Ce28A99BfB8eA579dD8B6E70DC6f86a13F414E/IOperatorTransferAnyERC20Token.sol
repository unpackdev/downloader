// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

interface IOperatorTransferAnyERC20Token {
     /**
     * Owner can withdraw any ERC20 token received by the contract
     */
    function operatorTransferAnyERC20Token(address token, address recipient, uint256 amount) external returns (bool success);
}
