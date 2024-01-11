// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IHyphen.sol";
import "./IBridge.sol";

contract HyphenProvider is ReentrancyGuard, IBridge, Ownable{
	using SafeERC20 for IERC20;
	address private constant NATIVE_TOKEN_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
	
	ILiquidityPool public hyphenLiquidityPool;

	// @notice Liquidty Pool Address required
	constructor(address _hyphen) {
		hyphenLiquidityPool = ILiquidityPool(_hyphen);
	}

	/**
	// @notice function responsible to bridge Native tokens
	// @param toChainId Id of destination chain
	// @param receiver Address of receiver
	// @param amount Amount to be bridged
	// param extraData extra data if needed
	 */
    function transferNative(uint amount, 
        address receiver, 
        uint64 toChainId, 
        bytes memory //extraData
		) external payable nonReentrant {
			require(msg.value == amount, "Wagpay: Please send amount greater than 0");
			require(msg.value != 0, "WagPay: Please send amount greater than 0");
			hyphenLiquidityPool.depositNative{value: amount}(receiver, toChainId, "WagPay");

			emit NativeFundsTransferred(receiver, toChainId, amount);
	}

	/**
	// @notice function responsible to bridge ERC20 tokens
	// @param toChainId Id of destination chain
	// @param tokenAddress Address of token to be bridged
	// @param receiver Address of receiver
	// @param amount Amount to be bridged
	// param extraData extra data if needed
	 */
	function transferERC20(
		uint64 toChainId,
        address tokenAddress,
        address receiver,
        uint256 amount,
        bytes memory //extraData
		) external nonReentrant {

			require(amount > 0, "WagPay: Please send amount greater than 0");

			IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
			IERC20(tokenAddress).safeIncreaseAllowance(address(hyphenLiquidityPool), amount);

			hyphenLiquidityPool.depositErc20(toChainId, tokenAddress, receiver, amount, "WagPay");
		
			emit ERC20FundsTransferred(receiver, toChainId, amount, tokenAddress);
	}

	/**
	// @notice function responsible to change pool address
	// @param  newPool address of new pool
	 */
	function changePool(address newPool) external onlyOwner {
		hyphenLiquidityPool = ILiquidityPool(newPool);
	}

	/**
	// @notice function responsible to rescue funds if any
	// @param  tokenAddr address of token
	 */
	function rescueFunds(address tokenAddr) external onlyOwner nonReentrant {
        if (tokenAddr == NATIVE_TOKEN_ADDRESS) {
            uint balance = address(this).balance;
            payable(msg.sender).transfer(balance);
        } else {
            uint balance = IERC20(tokenAddr).balanceOf(address(this));
            IERC20(tokenAddr).transferFrom(address(this), msg.sender, balance);
        }
    }
}