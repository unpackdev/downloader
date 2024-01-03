//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./GasTank.sol";
import "./Types.sol";
import "./SafeERC20.sol";
import "./ISwapAction.sol";

contract SwapSettlement is GasTank {
    
    using SafeMath for uint256;
    using SafeMath for uint112;
    using SafeMath for uint128;
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    //============= EVENT DEFS =================/
    event TraderPenalized(address indexed trader, uint256 penalty, uint256 gasPaid, string reason);
    event SwapFailed(address indexed trader, uint gasPaid, string reason);
    event SwapSuccess(address indexed trader,
                       address indexed executor, 
                       uint inputAmount,
                       uint outputAmount,
                       uint fee,
                       uint gasPaid);

    //============== CONSTANTS ==============/
    //estimate gas usage for testing a user's deposit
    uint256 constant GAS_ESTIMATE = 600_000;

    //extra overhead for transferring funds
    uint256 constant GAS_OVERHEAD = 60_000;

    //gas needed after action executes
    uint256 constant OP_GAS = 80_000;

    //============== VIEWS ================/

    // @dev determine if the given order can be filled. This tests the trader's 
    // current gas tank balance, whether they have tokens to trade, and whether
    // this contract has approval to trade.
    function canSwap(Types.Order memory order, uint256 gasPrice) public view returns (bool) {
        return _hasFunds(order, gasPrice) &&
               _hasTokens(order) &&
               _canSpend(order);
    }

    // @dev estimate how many swaps an owner can make before running out of funds 
    // at the given gas price
    function estimateSwapCount(address owner, uint256 gasPrice) public view returns (uint256) {
        uint112 bal = LibStorage.getGasStorage().balances[owner].balance; 
        //we only take into account what's fully available. If we included
        //locked funds, it might be withdrawn before trade occurs
        uint256 totalCost = gasPrice.mul(GAS_ESTIMATE);
        return bal.div(totalCost);
    }


    // @dev initialize the settlement contract 
    function initialize(Types.Config memory config) public initializer {
        BaseConfig.initConfig(config);
    }


    // @dev whether the trader has gas funds to support order at the given gas price
    function _hasFunds(Types.Order memory order, uint256 gasPrice) internal view returns (bool) {
        uint256 gas = GAS_ESTIMATE.mul(gasPrice);
        uint256 total = gas.add(order.fee).add(LibStorage.getConfigStorage().penaltyFee);
        
        bool b = this.hasEnoughGas(order.trader, total);
        //console.log("Has enough gas funds", b);
        return b;
    }

    // @dev whether the trader has a token balance to support input side of order
    function _hasTokens(Types.Order memory order) internal view returns (bool) {
        bool b = order.input.token.balanceOf(order.trader) >= order.input.amount;
        //console.log("Has tokens", b);
        return b;
    }

    // @dev whether the trader has approved this contract to spend enought for order
    function _canSpend(Types.Order memory order) internal view returns (bool) {
        bool b = order.input.token.allowance(order.trader, address(this)) >= order.input.amount;
        //console.log("Can spend tokens", b);
        return b;
    }

    

    //=============== MUTATIONS ==================/

    // @dev fill an order using the given script and calldata.
    function fill(
        Types.Order memory order,  
        ISwapAction script, 
        bytes memory data) public onlyRelay nonReentrant {

        uint256 startGas = gasleft();

        //if the trader ran out of funds, they can't pay so bail as quickly as possible
        require(_hasFunds(order, tx.gasprice), "Insufficient funds to pay for txn");

        //make sure not attempting bad script
        if(!hasRole(ACTION_ROLE, address(script))) {
            //console.log("Unapproved action script");
            _penalize(order, startGas, "Attempting to call unapproved action script");
            return;
        }

        //make sure tokens are still in tact
        if(!_hasTokens(order)) {
            _penalize(order, startGas, "Insufficient token balance for trade");
            return;
        }

        //make sure we are still allowed to transfer
        if(!_canSpend(order)) {
            _penalize(order, startGas, "Insufficient spend allowance for trade");
            return;
        }

        performSwap(order, script, data, startGas);
    }

    struct BalTracking {
        uint256 inBal;
        uint256 outBal;
        uint256 afterIn;
        uint256 actualOut;
    }

    function performSwap(
        Types.Order memory order, 
        ISwapAction script, 
        bytes memory data,
        uint startGas
    ) internal {

        //before balances
        BalTracking memory tracking = BalTracking(
            order.input.token.balanceOf(order.trader),
            order.output.token.balanceOf(order.trader),
            0, 
            0
        );
         
        bool success;
        string memory failReason;

        //execute action
        try this.trySwap{
            gas: gasleft().sub(OP_GAS)
        }(order, script, data) {

            //success, verify outputs
            success = true;
            
        } catch Error(string memory err) {
            success = false;
            failReason = err;
        } catch {
            success = false;
            failReason = "Unknown fail reason";
        }

        tracking.afterIn = order.input.token.balanceOf(order.trader);
        if(!success) {
            //console.log("Swap failed", failReason);
            //have to revert if funds were not refunded in order to roll everything back.
            //in this case, the action is at fault, which is owner's fault and therefore 
            //owner's relay address should eat the cost of failure
            require(tracking.afterIn == tracking.inBal, "failed swap action did not refund input funds");
            
            //otherwise, funds returned but something else is wrong like benign slippage
            //which the trader has to pay for since they set the slippage rate.
            
           
            //pay relayer back their gas but take no fee
            uint256 totalGasUsed = startGas.sub(gasleft()).add(GAS_OVERHEAD);
            uint256 gasFee = totalGasUsed.mul(tx.gasprice);
            deduct(order.trader, uint112(gasFee));
             //tell trader it failed
            emit SwapFailed(order.trader, gasFee, failReason);

            //console.log("Paying gas", gasFee);
            _msgSender().transfer(gasFee);
            return;
        }

        {
            tracking.actualOut = order.output.token.balanceOf(order.trader);
            //if the in/out amounts don't line up, then transfers weren't made properly in the
            //script.
            //console.log("Before output", outBal);
            //console.log("After output", afterOut);

            require(tracking.actualOut > tracking.outBal, "Insufficient output produced");
            require(tracking.actualOut.sub(tracking.outBal) >= order.output.amount, "Swap action did not transfer output tokens to trader");
            require(tracking.afterIn < tracking.inBal, "Input tokens not used!");
            require(tracking.inBal.sub(tracking.afterIn) <= order.input.amount, "Used too many input tokens");
            //otherwise, pay fee and gas
            uint256 totalGasUsed = startGas.sub(gasleft()).add(GAS_OVERHEAD);
            uint256 gasFee = totalGasUsed.mul(tx.gasprice);
            //console.log("Gas fee", gasFee);
            deduct(order.trader, uint112(gasFee.add(order.fee)));

            _msgSender().transfer(gasFee);
            payable(LibStorage.getConfigStorage().devTeam).transfer(order.fee);
        
            emit SwapSuccess(order.trader,
                        _msgSender(),
                        tracking.inBal.sub(tracking.afterIn),
                        tracking.actualOut.sub(tracking.outBal),
                        order.fee,
                        gasFee);
        }
    }

    function trySwap(Types.Order calldata order, ISwapAction script, bytes calldata data) external {
        require(msg.sender == address(this), "Can only be called by settlement contract");
        order.input.token.safeTransferFrom(order.trader, address(script), order.input.amount);
        
        (bool success, string memory failReason) = script.swap(order, data);
        if(!success) {
            revert(failReason);
        }
    }
    
    // @dev penalize the user due to missing funds or allowances
    function _penalize(Types.Order memory order, uint256 startGas, string memory reason) internal {
        uint128 fee = LibStorage.getConfigStorage().penaltyFee;

        

        //add additional gas for transfers and emit
        uint256 totalGasUsed = startGas.sub(gasleft()).add(GAS_OVERHEAD);
        uint256 gasFee = totalGasUsed.mul(tx.gasprice);
        //console.log("Gas fee", gasFee);
        //console.log("Penalty", fee);
        deduct(order.trader, uint112(fee.add(gasFee)));

        emit TraderPenalized(order.trader, uint256(fee), gasFee, reason);

        //pay penalty to dev team
        payable(LibStorage.getConfigStorage().devTeam).transfer(fee);

        //pay gas to relay
        _msgSender().transfer(gasFee);
    }
}