// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./PoolStore.sol";

contract PoolMigrator is Ownable {
    using SafeERC20 for IERC20;

    function migrate(
        address _from,
        address _to,
        address _token,
        address _target
    ) public onlyOwner {
        uint256 fromPid = IPoolStore(_from).poolIdsOf(_token)[0];
        uint256 toPid = IPoolStore(_to).poolIdsOf(_token)[0];
        uint256 amount = IPoolStore(_from).balanceOf(fromPid, _target);

        // withdraw
        IPoolStore(_from).withdraw(fromPid, _target, amount);

        // deposit
        IERC20(_token).safeIncreaseAllowance(_to, amount);
        IPoolStore(_to).deposit(toPid, _target, amount);
    }
}
