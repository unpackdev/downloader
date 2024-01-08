// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./SafeERC20.sol";

contract CrownyTokenBridge {
    using SafeERC20 for IERC20;

    IERC20 immutable __token;
    mapping(address => uint256) internal __deposits;

    event ConvertToSpl(address fromAddress, uint256 amount, string solanaAddress);

    constructor(IERC20 token) {
        __token = token;
    }

    function deposit(uint256 amount, string calldata solanaAddress) external isPositiveLamports(amount) {
        __token.safeTransferFrom(msg.sender, address(this), amount);

        __deposits[msg.sender] += amount;

        emit ConvertToSpl(msg.sender, amount, solanaAddress);
    }

    function tokenAddress() external view returns (address) {
        return address(__token);
    }

    function getDepositedAmount(address depositer) external view returns (uint256) {
        return __deposits[depositer];
    }

    modifier isPositiveLamports(uint256 amount) {
        require(amount >= 1000000, 'CrownyTokenBridge: Only positive lamports allowed');
        _;
    }
}
