//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./LibStorage.sol";
import "./Types.sol";

import "./console.sol";

library LibGas {
    using SafeMath for uint256;
    using SafeMath for uint112;
    using SafeMath for uint;

    //emitted when gas is deposited
    event GasDeposit(address indexed trader, uint112 amount);

    //emitted when gas is marked for thaw period
    event GasThawing(address indexed trader, uint112 amount);

    //emitted when gas is withdrawn
    event GasWithdraw(address indexed trader, uint112 amount);


    // ============ VIEWS ==============/
    /**
     * Determine how much of an account's gas tank balance can be withdrawn after a thaw period 
     * has expired.
     */
    function availableForWithdraw(Types.GasBalances storage gs, address account) external view returns (uint256) {
        Types.Gas storage gas = gs.balances[account];
        if(gas.thawingUntil > 0 && gas.thawingUntil <= block.number) {
            return gas.thawing;
        }
        return 0;
    }

    /**
     * Determine how much of an account's gas tank balance is availble to pay for fees
     */
    function availableForUse(Types.GasBalances storage gs, address account) internal view returns (uint256) {
        Types.Gas storage gas = gs.balances[account];
       
        //console.log("Current block", block.number);
        //console.log("Expired block", gas.thawingUntil);

        if(gas.thawingUntil > 0 && gas.thawingUntil > block.number) {
            //we have some funds thawing, which are still usable up until its expiration block
            return gas.balance.add(gas.thawing);
        }
        //otherwise we can only use balance funds
        return gas.balance;
    }
    
    /**
     * Determine how much of an account's gas tank is waiting for a thaw period before it's 
     * available for withdraw
     */
    function thawingFunds(Types.GasBalances storage gs, address account) internal view returns (uint256) {
        Types.Gas storage gas = gs.balances[account];
        //so long as the thaw period hasn't expired
        if(gas.thawingUntil > 0 && gas.thawingUntil > block.number) {
            //the funds are not available for withdraw
            return gas.thawing;
        }

        return 0;
    }

    /**
     * Determine if the account has enough in the tank to pay for estimated usage for given price
     */
    function hasEnough(Types.GasBalances storage gs, address account, uint256 estimateUse, uint112 price) internal view returns (bool) {
        require(price > 0, "Cannot estimate with 0 gas price");
        require(estimateUse > 0, "Cannot estimate with 0 gas use");
        uint112 amount = uint112(estimateUse.mul(price));
        uint112 _total = uint112(availableForUse(gs, account));
        
        return _total > amount;
    }


    // ============ MUTATIONS ==========/
    /**
     * Deposit funds into the gas tank.
     */
    function deposit(Types.GasBalances storage gs, address account, uint112 amount) internal {
        Types.Gas storage gas = gs.balances[account];

        //add incoming amount to the current balance
        gas.balance = uint112(gas.balance.add(amount));

        //tell the world about it
        emit GasDeposit(account, amount);
    }

    /**
     * Mark 
     */
    function thaw(Types.GasBalances storage gs, address account, uint112 amount) internal {
        Types.Gas storage gas = gs.balances[account];
        //following will fail if amount is more than gas tank balance so no need
        //to check and waste cycles
        gas.balance = uint112(gas.balance.sub(amount));

        //add to thawing total
        gas.thawing = uint112(gas.thawing.add(amount));

        //set withdraw to next lockout period blocks. Note that this locks up any
        //previously thawed funds as well.
        gas.thawingUntil = block.number.add(LibStorage.getConfigStorage().lockoutBlocks);

        //tell the world about it
        emit GasThawing(account, amount);
    }

    
    /**
     * Try to withdraw any fully thawed funds
     */
    function withdraw(Types.GasBalances storage gs, address account, uint112 amount) internal {
        Types.Gas storage gas = gs.balances[account];
        require(gas.thawingUntil > 0, "Must first request a withdraw");
        require(gas.thawingUntil < block.number, "Cannot withdraw inside lockout period");

        //this will fail if amount is more than thawing amount so no need to check amount
        gas.thawing = uint112(gas.thawing.sub(amount));
    }

    /**
     * Deduct from the trader's balance after an action is complete
     */
    function deduct(Types.GasBalances storage gs, address account, uint112 amount) internal {
        Types.Gas storage gas = gs.balances[account];
        if(amount == 0) {
            return;
        }
        uint112 _total = uint112(availableForUse(gs, account));

        require(_total > amount, "Insufficient gas to pay amount");
        if(gas.balance >= amount) {
            //if the balance has enough to pay, just remove it
            gas.balance = uint112(gas.balance.sub(amount));
        } else {
            //otherwise, this means there are thawing funds that have not fully thawed yet
            //but are stll available for use. So use them.
            gas.thawing = uint112(gas.thawing.sub(amount.sub(gas.balance)));
            gas.balance = 0;
        }
    }
}