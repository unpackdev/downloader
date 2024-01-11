// SPDX-License-Identifier: MIT
pragma solidity >=0.7;

import "./Math.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./StrayCollector.sol";
import "./console.sol";

contract CoinsulSwap is Ownable, StrayCollector {
    address public aggregationRouter;
    uint256 MAX_INT = 2**256-1;

    event Swap(
        address indexed userAddress,
        address indexed srcToken,
        address indexed dstToken,
        uint256 amount,
        uint256 minReturnAmount,
        uint256 returnAmount,
        address sender
    );

    constructor(address routerAddress) {
        aggregationRouter = routerAddress;
    }

    function swap(
        bytes calldata _data,
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 minReturn,
        address userAddress
    ) external payable returns (uint256) {
        //check for approval
        if (
            IERC20(sellToken).allowance(address(this), aggregationRouter) == 0
        ) {
            IERC20(sellToken).approve(aggregationRouter, MAX_INT);
        }
        // transfer tokens from msg.sender
        IERC20(sellToken).transferFrom(msg.sender, address(this), sellAmount);

        // make the swap, and return the actual amount received
        uint256 returnAmount = 0;

        (bool succ, ) = address(aggregationRouter).call(_data);
        console.log("successful swap: ", succ);
        if (succ) {
            returnAmount = IERC20(buyToken).balanceOf(address(this));
            console.log("returnAmount", returnAmount);
            console.log("minReturn", minReturn);
            require(returnAmount >= minReturn, "insufficient return amount");
            IERC20(buyToken).transfer(userAddress, returnAmount);
        } else {
            revert("1inch reported failure");
        }

        emit Swap(userAddress, sellToken, buyToken, sellAmount, minReturn, returnAmount, msg.sender);

        return returnAmount;
    }

    // can change the 1inch aggregator address if needed
    function setAggregationAddress(address newAggregator) external onlyOwner {
        aggregationRouter = newAggregator;
    }
}
