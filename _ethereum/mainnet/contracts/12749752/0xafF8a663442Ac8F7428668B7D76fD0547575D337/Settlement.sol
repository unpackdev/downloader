//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IDexRouter.sol";
import "./BaseConfig.sol";
import "./SafeERC20.sol";
import "./Types.sol";

interface IERC20Metadata {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract Settlement is BaseConfig {

    using SafeMath for uint256;
    using SafeMath for uint112;
    using SafeMath for uint128;
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    //============= EVENT DEFS =================/
    event TraderPenalized(address indexed trader, uint256 penalty, uint256 gasPaid, string reason);
    event SwapFailed(address indexed trader, string reason);
    event SwapSuccess(address indexed trader,
                       address indexed executor, 
                       uint inputAmount,
                       uint outputAmount);
    event ReceivedETH(address indexed sender, uint amount);
    event WithdrewETH(address indexed receiver, uint amount);
    event PaidGasFunds(address indexed sender, uint amount);
    event InsufficientGasFunds(address indexed caller, uint amount);

    //============== CONSTANTS ==============/
    //gas needed after action executes
    uint256 constant OP_GAS = 80_000;

    //for final transfers and events
    uint256 constant GAS_OVERHEAD = 20_000;

    struct BalTracking {
        uint256 inBal;
        uint256 outBal;
        uint256 afterIn;
        uint256 afterOut;
    }

    receive() external payable {
        emit ReceivedETH(msg.sender, msg.value);
    }

    /**
     * Fill an order using the given router and forwarded call data.
     */
    function fill(Types.Order memory order, IDexRouter router, bytes calldata data) public onlyRelay nonReentrant {

        uint256 startGas = gasleft();
        //pre-trade condition checks
        BalTracking memory _tracker = _preCheck(order);

        //execute action
        (bool success, string memory failReason) = performFill(order, router, data);

        //post-trade condition check
        _postCheck(order, _tracker, success);

        //post-trade actions to transfer fees, etc.
        _postActions(order, success, failReason, _tracker, startGas);
    } 

    /**
     * Team's ability to withdraw ETH balance from the contract.
     */
    function withdraw(uint amount) public onlyAdmin {
        require(amount < address(this).balance, "Insufficient balance to make transfer");
        _msgSender().transfer(amount);
        emit WithdrewETH(_msgSender(), amount);
    }

    // @dev initialize the settlement contract 
    function initialize(Types.Config memory config) public initializer {
        BaseConfig.initConfig(config);
    }

    // @dev whether the trader has a token balance to support input side of order
    function _hasTokens(Types.Order memory order) internal view returns (bool) {
        bool b = order.input.token.balanceOf(order.trader) >= order.input.amount;
        return b;
    }

    // @dev whether the trader has approved this contract to spend enought for order
    function _canSpend(Types.Order memory order) internal view returns (bool) {
        bool b = order.input.token.allowance(order.trader, address(this)) >= order.input.amount;
        return b;
    }

    function _preCheck(Types.Order memory order) internal view returns (BalTracking memory) {
        //require(_hasFunds(order, tx.gasprice), "Insufficient gas tank funds");
        require(_hasTokens(order), "Insufficient input token balance to trade");
        require(_canSpend(order), "Insufficient spend allowance on input token");
        //before balances
        return BalTracking(
            order.input.token.balanceOf(order.trader),
            order.output.token.balanceOf(order.trader),
            0,0
        );
    }

    function _preActions(Types.Order memory order, IDexRouter router) internal {
        //transfer input tokens to router so it can perform dex trades
        order.input.token.safeTransferFrom(order.trader, address(router), order.input.amount);
    }

    function performFill(Types.Order memory order, IDexRouter router, bytes calldata data) internal returns (bool success, string memory failReason) {
        //execute action. This is critical that we use our own internal call to actually
        //perform swap inside trycatch. This way, transferred funds to script are 
        //reverted if swap fails
        try this._trySwap{
            gas: gasleft().sub(OP_GAS)
        }(order, router, data) returns (bool _success, string memory _failReason) {
            return (_success, _failReason);
        } catch Error(string memory err) {
            success = false;
            failReason = err;
        } catch {
            success = false;
            failReason = "Unknown fail reason";
        }
    }

    function _trySwap(Types.Order calldata order, IDexRouter router, bytes calldata data) external returns (bool success, string memory failReason) {
        require(msg.sender == address(this), "Can only be called by settlement contract");
        _preActions(order, router);
        (bool s, string memory err) = router.fill(order, data);
        if(!s) {
            revert(err);
        }
        return (s, err);
    }

    function _postCheck(Types.Order memory order, BalTracking memory _tracking, bool success) internal view {
        
        _tracking.afterIn = order.input.token.balanceOf(order.trader);

        if(!success) {
            //have to revert if funds were not refunded in order to roll everything back.
            //in this case, the router is at fault, which is Dexible's fault and therefore 
            //Dexible relay address should eat the cost of failure
            console.log("Input bal b4", _tracking.inBal);
            console.log("Input bal after", _tracking.afterIn);
            require(_tracking.afterIn == _tracking.inBal, "failed trade action did not refund input funds");
        } else {
            _tracking.afterOut = order.output.token.balanceOf(order.trader);
            //if the in/out amounts don't line up, then transfers weren't made properly in the
            //router.

            console.log("Trader token balance before swap", _tracking.outBal);
            console.log("New trader balance", _tracking.afterOut);
            require(_tracking.afterOut.sub(_tracking.outBal) >= order.output.amount, "Trade action did not transfer output tokens to trader");
            require(_tracking.afterIn < _tracking.inBal, "Input tokens not used!");
            require(_tracking.inBal.sub(_tracking.afterIn) <= order.input.amount, "Used too many input tokens");
        }
          
    }

    function _postActions(Types.Order memory order, 
                          bool success, 
                          string memory failReason, 
                          BalTracking memory _tracking,
                          uint startGas) internal {
        if(!success) {
            //tell trader it failed
            emit SwapFailed(order.trader,failReason);
        } else {
            uint256 grossOut = _tracking.afterOut.sub(_tracking.outBal);
            uint256 totalGasUsed = startGas.sub(gasleft()).add(GAS_OVERHEAD);
            uint256 gasFee = totalGasUsed.mul(tx.gasprice);
            if(address(this).balance < gasFee) {
                emit InsufficientGasFunds(_msgSender(), gasFee);
            } else {
                _msgSender().transfer(gasFee);
                emit PaidGasFunds(_msgSender(), gasFee);
            }
            
            emit SwapSuccess(order.trader,
                        _msgSender(),
                        _tracking.inBal.sub(_tracking.afterIn),
                        grossOut); 
        }
    }
}