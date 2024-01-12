// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
pragma abicoder v2;

import "./IUniswapV3FlashCallback.sol";
import "./IUniswapV3Pool.sol";
import "./PeripheryPayments.sol";
import "./PeripheryImmutableState.sol";
import "./PoolAddress.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

/// @title Flashloan contract implementation
/// @notice contract using the Uniswap V3 flash function
contract Uniswap3Flash is 
    IUniswapV3FlashCallback,
    PeripheryImmutableState,
    PeripheryPayments,
    ReentrancyGuard,
    Ownable {
    using SafeMath for uint256;
    struct FlashCallbackData {
        address token;
        uint256 amount;
        address payer;
    }
    struct Call {
        address to;
        bytes data;
    }
    uint24 public flashPoolFee = 500;  //  flash from the 0.05% fee of pool
    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    constructor(
        address _factory,
        address _WETH9
    ) PeripheryImmutableState(_factory, _WETH9) {}
    function initFlashloan(
        address loanToken,
        uint256 loanAmount,
        Call[] calldata calls
    ) external payable nonReentrant {
        address otherToken = loanToken == WETH9 ? DAI : WETH9;
        (address token0, address token1) = loanToken < otherToken ? (loanToken, otherToken) : (otherToken, loanToken);
        uint256 amount0 = loanToken == token0 ? loanAmount : 0;
        uint256 amount1 = loanToken == token1 ? loanAmount : 0;
        
        address flashPool = PoolAddress.computeAddress(
            factory, 
            PoolAddress.PoolKey(token0, token1, flashPoolFee)
        );
        require(flashPool != address(0), "Invalid flash pool!");
        FlashCallbackData memory callbackData = FlashCallbackData({
            token: loanToken,
            amount: loanAmount,
            payer: msg.sender
        });
        IUniswapV3Pool(flashPool).flash(
            address(this),
            amount0,
            amount1,
            abi.encode(
                callbackData,
                flashPool,
                calls
            )
        );  
    }

    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external override {
        (
            FlashCallbackData memory callback,
            address flashPool,
            Call[] memory calls
        ) = abi.decode(data, (FlashCallbackData, address, Call[]));
        require(msg.sender == flashPool, "Only Pool can call!");
        
        address loanToken = callback.token;
        uint256 loanAmount = callback.amount;
        uint256 fee = fee0 > 0 ? fee0 : fee1;
        // start trade
        for (uint i = 0; i < calls.length; i++) {
           // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = calls[i].to.call(calls[i].data);
            require(success, "Trading Failure!");
        }
        uint256 amountOut = IERC20(loanToken).balanceOf(address(this));
        uint256 amountOwed = loanAmount.add(fee);
        
        if (amountOut >= amountOwed) {
            pay(loanToken, address(this), flashPool, amountOwed);
        }
        uint256 profit = amountOut.sub(amountOwed);
        if (profit > 0) {
            pay(loanToken, address(this), callback.payer, profit);
        }
    }
    function changeFlashPoolFee(uint24 poolFee) public onlyOwner() {
        flashPoolFee = poolFee;
    }
    fallback() external payable {}
    receive() external payable {}
}
