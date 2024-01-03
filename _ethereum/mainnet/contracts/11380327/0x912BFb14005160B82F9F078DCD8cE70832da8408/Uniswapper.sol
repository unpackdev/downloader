//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;


import "./SafeMath.sol";
import "./Types.sol";
import "./ISwapAction.sol";
import "./BaseAccess.sol";

import "./IPair.sol";
import "./IPairFactory.sol";
import "./IV2Router.sol";

import "./console.sol";

contract Uniswapper is BaseAccess, ISwapAction {
    using SafeMath for uint256;
    using SafeMath for uint112;
    using SafeMath for uint;

    IPairFactory factory;
    IV2Router router;

    function initialize(IPairFactory uniFactory, IV2Router v2Router) public initializer {
        BaseAccess.initAccess();
        factory = uniFactory;
        router = v2Router;
    }

    //=========== VIEWS ==============//
    function getQuote(Types.Order memory order) public view returns (uint) {
        if(order.orderType == Types.OrderType.EXACT_IN) {
            (uint amount, ) = _getOutputQuote(order);
            return amount;
        }
        (uint amount, ) = _getInputQuote(order);
        return amount;
    }

    

    function _getOutputQuote(Types.Order memory order) internal view returns (uint, IPair) {
        address pA = factory.getPair(address(order.input.token), address(order.output.token));
        
        require(pA != address(0), "No token pair found");
        IPair pair = IPair(pA);
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (address tA, ) = _sortTokens(address(order.input.token), address(order.output.token));
        (uint reserveA, uint reserveB) = address(order.input.token) == tA ? (reserve0, reserve1) : (reserve1, reserve0);

        return (router.getAmountOut(order.input.amount, reserveA, reserveB), pair);
    }

    function _getInputQuote(Types.Order memory order) internal view returns (uint, IPair) {
        address pA = factory.getPair(address(order.input.token), address(order.output.token));
        
       
        require(pA != address(0), "No token pair found");
        IPair pair = IPair(pA);
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (address tA, ) = _sortTokens(address(order.input.token), address(order.output.token));
        (uint reserveA, uint reserveB) = address(order.output.token)  == tA ? (reserve0, reserve1) : (reserve1, reserve0);

        return (router.getAmountIn(order.output.amount, reserveA, reserveB), pair);
    }



    //=========== MUTATIONS =============/

    function swap(Types.Order calldata order, bytes calldata data) external override  returns (bool, string memory failReason) {
        if(order.orderType == Types.OrderType.EXACT_IN) {
            return _exactIn(order);
        }
        return _exactOut(order);
    }

    function _exactIn(Types.Order memory order) internal returns (bool, string memory) {
        if(order.input.token.balanceOf(address(this)) < order.input.amount) {
            return (false, "Input funds not transferred to swap");
        }

        //console.log("Amount out", amount);
        //console.log("Expected output", order.output.amount);
        (uint amount, IPair pair) = _getOutputQuote(order);
        if(amount < order.output.amount) {
            return (false,'Excessive output required');
        }
        bool success = false;
        string memory failReason = "";
        try order.input.token.transfer{
            gas: gasleft()
        }(address(pair), order.input.amount){
            success = true;
        } catch Error(string memory err) {
            success = false;
            failReason = err;
        } catch {
            success = false;
            failReason = "Unknown fail reason";
        }
        
        if(!success) {
            return (false, failReason);
        }

        (address token0, ) = address(order.input.token) > address(order.output.token) ? 
                (address(order.output.token),address(order.input.token)) : 
                (address(order.input.token), address(order.output.token));

        (uint amount0Out, uint amount1Out) = 
                address(order.input.token) == token0 ? (uint(0), amount) : (amount, uint(0));


        try pair.swap{
            gas: gasleft()
        }(amount0Out, amount1Out, order.trader, new bytes(0)){

            success = true;

        } catch Error(string memory err) {
            success = false;
            failReason = err;
        } catch {
            success = false;
            failReason = "Unknown fail reason";
        }
        if(!success) {
            return(false, failReason);
        }
        return (true, "");
    }

    

    function _exactOut(Types.Order memory order) internal returns (bool, string memory) {

        if(order.input.token.balanceOf(address(this)) < order.input.amount) {
            return (false, "Input funds not transferred to swap");
        }

        (uint amount, IPair pair) = _getInputQuote(order);

        //console.log("Amount in", amount);
        //console.log("Expected input", order.input.amount);
       
        if(amount > order.input.amount) {
            return (false, 'Insufficient input provided');
        }

        order.input.token.transfer(address(pair), amount);

        bool success = false;
        string memory failReason = "";
        (address token0, ) = _sortTokens(address(order.input.token), address(order.output.token)); 

        //make sure output is attached to correct sorted token address in pair
        (uint amount0Out, uint amount1Out) = 
                address(order.input.token) == token0 ? (uint(0), uint(order.output.amount)) : (uint(order.output.amount), uint(0));


        try pair.swap{
            gas: gasleft().sub(40000)
        }(amount0Out, amount1Out, order.trader, new bytes(0)) {

            success = true;

        } catch Error(string memory err) {
            success = false;
            failReason = err;
        } catch {
            success = false;
            failReason = "Unknown fail reason";
        }
        if(!success) {
            return(false, failReason);
        }

        uint diff = order.input.amount.sub(amount);
        if(diff > 0) {
            //transfer any extra back to trader
            order.input.token.transfer(order.trader, diff);
        }
        return (true, "");
    }

    function _sortTokens(address a, address b) internal pure returns (address, address) {
        return a > b ? (b, a) : (a, b);
    }
}