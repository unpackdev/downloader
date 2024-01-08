//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


import "./SafeMath.sol";
import "./Types.sol";
import "./IDexRouter.sol";
import "./BaseAccess.sol";

import "./IPair.sol";
import "./IPairFactory.sol";
import "./IV2Router.sol";

import "./console.sol";

contract UniswapDex is BaseAccess, IDexRouter{
    using SafeMath for uint256;
    using SafeMath for uint112;
    using SafeMath for uint;

    uint256 constant public MAX_INT_TYPE = type(uint256).max;

    IPairFactory factory;
    IV2Router router;

    function initialize(IPairFactory uniFactory, IV2Router v2Router) public initializer {
        BaseAccess.initAccess();
        factory = uniFactory;
        router = v2Router;
    }

    function revokeTokenAllowance(IERC20 token) external onlyAdmin {
        token.approve(address(router), 0);
    }

    function fill(Types.Order calldata order, bytes calldata data) external override returns (bool success, string memory failReason) {
        address[] memory path = abi.decode(data, (address[]));
        verifyRouterAllowance(order.input.token, order.input.amount);
        if(order.orderType == Types.OrderType.EXACT_IN) {
            //console.log("Expecting output amount", order.output.amount);

            try router.swapExactTokensForTokens{
                gas: gasleft()
            }(
                order.input.amount, 
                order.output.amount, 
                path, 
                order.trader,
                block.timestamp+1
            ) 
            {
                success = true;
            } catch Error(string memory err) {
                //console.log("Problem in fill", err);
                success = false;
                failReason = err;
            } catch {
                success = false;
                failReason = "Unknown fail reason";
            }
        } else {
            try router.swapTokensForExactTokens{
                gas: gasleft()
            }(
                order.output.amount,
                order.input.amount,
                path,
                order.trader,
                block.timestamp + 1
            )
            {
                success = true;
            } catch Error(string memory err) {
                success = false;
                failReason = err;
            } catch {
                success = false;
                failReason = "Unknown fail reason";
            }
        }
    }

    function verifyRouterAllowance(IERC20 token, uint256 minAmount) internal {
        uint allow = token.allowance(address(this), address(router));
        if(allow < minAmount) {
            token.approve(address(router), minAmount);
        }
    }
}