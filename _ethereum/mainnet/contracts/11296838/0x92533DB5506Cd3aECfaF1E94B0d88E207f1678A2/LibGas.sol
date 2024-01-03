//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./LibStorage.sol";
import "./Types.sol";

library LibGas {
    using SafeMath for uint256;
    using SafeMath for uint112;
    using SafeMath for uint;

    // ============ VIEWS ==============/
    function availableForWithdraw(Types.GasBalances storage gs, address account) external view returns (uint256) {
        Types.Gas storage gas = gs.balances[account];
        if(gas.lockedUntil > 0 && gas.lockedUntil < block.number) {
            return gas.locked;
        }
        return 0;
    }

    function total(Types.GasBalances storage gs, address account) internal view returns (uint256) {
        Types.Gas storage gas = gs.balances[account];
        return gas.balance.add(gas.locked);
    }
    
    function lockedFunds(Types.GasBalances storage gs, address account) internal view returns (uint256) {
        Types.Gas storage gas = gs.balances[account];
        if(gas.lockedUntil > 0 && gas.lockedUntil > block.number) {
            return gas.locked;
        }
        return 0;
    }


    // ============ MUTATIONS ==========/
    function deposit(Types.GasBalances storage gs, address account, uint112 amount) internal {
        Types.Gas storage gas = gs.balances[account];
        gas.balance = uint112(gas.balance.add(amount));
    }

    function lock(Types.GasBalances storage gs, address account, uint112 amount) internal {
        Types.Gas storage gas = gs.balances[account];

        gas.balance = uint112(gas.balance.sub(amount));
        gas.locked = uint112(gas.locked.add(amount));
        gas.lockedUntil = block.number.add(LibStorage.getConfigStorage().lockoutBlocks);
    }

    function hasEnough(Types.GasBalances storage gs, address account, uint256 estimateUse, uint112 price) internal view returns (bool) {
        Types.Gas storage gas = gs.balances[account];
        require(price > 0, "Cannot estimate with 0 gas price");
        require(estimateUse > 0, "Cannot estimate with 0 gas use");
        uint112 amount = uint112(estimateUse.mul(price));
        uint112 _total = gas.balance;

        if(gas.lockedUntil > block.number) {
            _total = uint112(_total.add(gas.locked));
        }
        return _total > amount;
    }

    function withdraw(Types.GasBalances storage gs, address account, uint112 amount) internal {
        Types.Gas storage gas = gs.balances[account];
        require(gas.lockedUntil > 0, "Must first request a withdraw");
        require(gas.lockedUntil < block.number, "Cannot withdraw inside lockout period");
        gas.locked = uint112(gas.locked.sub(amount));
    }

    function deduct(Types.GasBalances storage gs, address account, uint112 amount) internal {
        Types.Gas storage gas = gs.balances[account];
        if(amount == 0) {
            return;
        }
        uint112 _total = uint112(gas.balance.add(gas.locked));

        require(_total > amount, "Insufficient gas to pay amount");
        if(gas.balance >= amount) {
            gas.balance = uint112(gas.balance.sub(amount));
        } else {
            //use up remaining balance and take the rest from locked
            gas.locked = uint112(gas.locked.sub(amount.sub(gas.balance)));
            gas.balance = 0;
        }
    }
}