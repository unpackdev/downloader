// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9.0;

import "./Utils.sol";
import "./GrokCore.sol";

/**
 * Grok的控制合约
 */
contract GrokCtrl is Base {
    // Grok核心合约地址
    address private _GrokCoreAddress;

    // Grok控制合约的构建函数
    constructor(address GrokCoreAddress) isContract(GrokCoreAddress) {
        _GrokCoreAddress = GrokCoreAddress; //为控制合约绑定核心合约
    }

    // 转移合约所有权
    function moveOwner(address to) external onlyOwner isExternal(to) {
        transferOwnership(to);
    }

    // 冻结Grok控制合约的所有转账操作
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    // 解除Grok控制合约的转账冻结
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    // 获取Grok的当前余额
    function currentBalance() public view returns (uint256) {
        return IERC20(_GrokCoreAddress).balanceOf(owner());
    }
}