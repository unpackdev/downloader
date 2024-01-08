// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Pair.sol";
import "./LpTokensStorage.sol";

abstract contract UsersStorage is LpTokensStorage {
    using SafeMath for uint256;
    using SafeERC20 for IUniswapV2Pair;

    struct UserInfo {
        bool userExists;
        uint256 amount;
        uint256 rewardPending;
    }
    // poolId => account => UserInfo
    mapping (uint256 => mapping (address => UserInfo)) public _userInfo;

    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed poolId, uint256 amount);

    // Deposit LP tokens to Farm for ERC20 allocation.
    function deposit(uint256 poolId, uint256 amount) public {
        require(poolId < _poolInfoCount, "deposit: Pool is not exists");
        PoolInfo storage pool = _poolInfo[poolId];
        require(amount > 0, "deposit: can't deposit zero amount");
        UserInfo storage user = _userInfo[poolId][msg.sender];
        user.userExists = true;

        _beforeBalanceChange(pool, msg.sender);

        user.amount = user.amount.add(amount);
        pool.lpToken.safeTransferFrom(address(msg.sender), amount);
        emit Deposit(msg.sender, poolId, amount);

        _afterBalanceChange(pool, msg.sender);
    }
    // Withdraw LP tokens from Farm.
    function withdraw(uint256 poolId, uint256 amount) public {
        require(poolId < _poolInfoCount, "withdraw: Pool is not exists");
        PoolInfo storage pool = _poolInfo[poolId];
        require(amount > 0, "withdraw: can't withdraw zero amount");
        UserInfo storage user = _userInfo[poolId][msg.sender];
        require(user.amount >= amount, "withdraw: can't withdraw more than deposit");

        _beforeBalanceChange(pool, msg.sender);

        user.amount = user.amount.sub(amount);
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit Withdraw(msg.sender, poolId, amount);

        _afterBalanceChange(pool, msg.sender);
    }
    function _beforeBalanceChange(PoolInfo storage pool, address account) internal virtual {}
    function _afterBalanceChange(PoolInfo storage pool, address account) internal virtual {}
}