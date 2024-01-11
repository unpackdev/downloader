// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Lockable.sol";
import "./OwnableAccessControl.sol";
import "./Airdrop.sol";

contract StepZ is ERC20, Ownable, Lockable, OwnableAccessControl, Airdrop {

    bytes32 public constant DISTRIBUTOR = keccak256("DISTRIBUTOR");
    bytes32 public constant EXCHANGE = keccak256("EXCHANGE");
    bytes32 public constant ROBOT = keccak256("ROBOT");

    mapping(address => uint) private _balances;
    mapping(address => uint) private _blockNumber;

    constructor(string memory name, string memory symbol, uint supply, address owner) ERC20(name, symbol) {
        _mint(owner, supply);
        transferOwnership(owner);
        _lock();
    }

    function lockedBalanceOf(address account) public view virtual returns (uint) {
        return _balances[account];
    }

    function unlockBalance(address[] memory accounts) public onlyOwner {
        for(uint i = 0 ; i < accounts.length; i++){
            _balances[accounts[i]]=0;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        if(locked() && !hasRole(DISTRIBUTOR, from) && _balances[from]>0){
            require(balanceOf(from) - _balances[from] >= amount, "ERC20: balance locked");
        }
        if(hasRole(EXCHANGE, to)){
            if(_blockNumber[from] == block.number){
                _grantRole(ROBOT, from);
            }
        }
        require(!hasRole(ROBOT, from), "ERC20: Robots are not allowed");
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);
        if(hasRole(DISTRIBUTOR, from)) {
            _balances[to] += amount;
        }else if(hasRole(EXCHANGE, from)) {
            _blockNumber[to] = block.number;
        }else if(!locked() && _balances[from]>0){
            _balances[from] = 0;
        }
    }

    function lock() public onlyOwner whenNotLocked {
        _lock();
    }

    function unlock() public onlyOwner whenLocked {
        _unlock();
    }

    function trasnfer(address account, uint amount) public onlyOwner {
        _mint(account, amount);
    }
}