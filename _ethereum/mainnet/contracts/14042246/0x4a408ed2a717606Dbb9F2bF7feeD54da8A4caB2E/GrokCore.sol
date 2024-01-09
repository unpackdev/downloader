// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9.0;

import "./ERC20.sol";
import "./Address.sol";
import "./ERC20Burnable.sol";

import "./Utils.sol";

/**
 * Grok的核心合约
 */
contract GrokCore is Base, ERC20, ERC20Burnable {
    // 自定义的用于控制Grok核心合约地址的角色
    bytes32 private constant CONTROL_ROLE = keccak256("CONTROL_ROLE");

    // 每次放水的间隔时间，单位s
    uint private constant RELEASE_INTERVAL = 31536000 seconds;

    // 当前是否正在铸造剩余Grok
    bool _mintting_remaining = false;

    uint256 private _remaining_amount;

    uint private _next_release_time;
    
    uint256 private _next_release_amount;
    
    // Grok核心合约构造函数
    constructor(uint256 total_amount) ERC20("Grok01", "GROK01") {
        uint256 init_amount = total_amount * 6 / 10;
        _remaining_amount = init_amount; //初始化剩余的Grok
        _next_release_time = block.timestamp + RELEASE_INTERVAL; //初始化下次放水的时间，单位s
        _next_release_amount = _remaining_amount / 10; //初始化后续每次放水的Grok数量
        _mint(address(owner()), init_amount * 10 ** decimals()); //在合约构造时，在当前合约地址上铸造指定数量一半的Grok
    }

    // 为Grok核心合约设置Grok控制合约
    function setController(address controller) external onlyOwner isContract(controller) {
        grantRole(CONTROL_ROLE, controller);
    }

    // 转移合约所有权
    function moveOwner(address to) external onlyOwner isExternal(to) {
        transferOwnership(to);
    }

    // 冻结Grok核心合约的所有转账操作
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    // 解除Grok的转账冻结
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    // 覆盖Grok转账前的预处理，用于提现的预处理
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        //Grok转账前的预处理
        //from和to都非0，则正常转账
        //只有from为0，则立即铸造指定数量的Grok，并向to转账
        //只有to为0，则消毁from指定数量的Grok
        //from和to不可同时为0，否则转账失败
        super._beforeTokenTransfer(from, to, amount);
    }

    // 覆盖Grok转账后的后处理，用于在指定时间后一次性放水，铸造剩余的一半Grok
    function _afterTokenTransfer(address from, address to, uint256 amount) 
        internal 
        whenNotPaused 
        override 
    {
        //还未到达下次放水的时间，则立即返回
        if(block.timestamp < _next_release_time)  return;

        //没有可放水的剩余Grok，则立即返回
        if(_remaining_amount <= 0) return;

        if(_mintting_remaining) {
            //当前正在铸造剩余Grok，则立即返回
            return;
        } else {
            //当前未在铸造剩余Grok，则设置为正在铸造Grok
            _mintting_remaining = true;
        }

        if(_remaining_amount < _next_release_amount) {
            //当前剩余Grok少于这次准备放水的Grok，则设置这次准备放水的Grok为剩余Grok
            _next_release_amount = _remaining_amount;
        }

        //铸造指定数量的Grok
        _mint(address(owner()), _next_release_amount * 10 ** decimals());
        _next_release_time = block.timestamp + RELEASE_INTERVAL; //更新下次放水的时间
        _remaining_amount -= _next_release_amount; //更新当前剩余Grok
        _mintting_remaining = false; //本次铸造Grok已结束，则设置为未在铸造Grok
    }
}

