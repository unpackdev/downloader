// SPDX-License-Identifier: MPL-2.0
pragma solidity 0.8.7;

import "./IUniswapV2Router02.sol";
import "./ILockup.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./SwapAndStakeV2.sol";

/// @title Swap and Stake V2 for Ethereum L1
contract SwapAndStakeV2L1 is SwapAndStakeV2 {
	constructor(
		address _uniswapRouterAddress,
		address _devAddress,
		address _lockupAddress,
		address _sTokensAddress
	)
		SwapAndStakeV2(
			_uniswapRouterAddress,
			_devAddress,
			_lockupAddress,
			_sTokensAddress
		)
	{}

	/// @notice Swap eth -> dev and stake
	/// @param property the property to stake after swap
	/// @param deadline refer to https://docs.uniswap.org/protocol/V1/guides/trade-tokens#deadlines
	/// @param payload allows for additional data when minting SToken
	function swapEthAndStakeDev(
		address property,
		uint256 deadline,
		bytes32 payload
	) external payable {
		gatewayOf[address(0)] = Amounts(msg.value, 0);

		_swapEthAndStakeDev(msg.value, property, deadline, payload);

		delete gatewayOf[address(0)];
	}

	/// @notice Swap eth -> dev and stake with GATEWAY FEE (paid in ETH) and payload
	/// @param property the property to stake after swap
	/// @param deadline refer to https://docs.uniswap.org/protocol/V1/guides/trade-tokens#deadlines
	/// @param payload allows for additional data when minting SToken
	/// @param gatewayAddress is the address to which the liquidity provider fee will be directed
	/// @param gatewayFee is the basis points to pass. For example 10000 is 100%
	function swapEthAndStakeDev(
		address property,
		uint256 deadline,
		bytes32 payload,
		address payable gatewayAddress,
		uint256 gatewayFee
	) external payable {
		require(gatewayFee <= 10000, "must be below 10000");

		// handle fee
		uint256 feeAmount = (msg.value * gatewayFee) / 10000;
		_deposit(gatewayAddress, feeAmount, address(0));

		gatewayOf[gatewayAddress] = Amounts(msg.value, feeAmount);

		_swapEthAndStakeDev(
			(msg.value - feeAmount),
			property,
			deadline,
			payload
		);

		delete gatewayOf[gatewayAddress];
	}

	/// @notice get estimated DEV output from ETH input
	/// @param ethAmount in ETH
	/// @return outputs UniSwap Router Outputs
	function getEstimatedDevForEth(uint256 ethAmount)
		external
		view
		returns (uint256[] memory)
	{
		return _getEstimatedDevForEth(ethAmount, _getPathForEthToDev);
	}

	/// @notice get estimated ETH output from DEV input
	/// @param devAmount in ETH
	/// @return outputs UniSwap Router Outputs
	function getEstimatedEthForDev(uint256 devAmount)
		external
		view
		returns (uint256[] memory)
	{
		return _getEstimatedEthForDev(devAmount, _getPathForEthToDev);
	}

	//=================================== INTERNAL ==============================================
	/// @notice Path from ETH -> DEV for uniswap router
	/// @return Path address array
	function _getPathForEthToDev()
		internal
		view
		virtual
		returns (address[] memory)
	{
		address[] memory path = new address[](2);
		path[0] = uniswapRouter.WETH();
		path[1] = devAddress;

		return path;
	}

	/// @notice Swap eth -> dev handles transfer and stake with payload
	/// @param amount in ETH
	/// @param property the property to stake after swap
	/// @param deadline refer to https://docs.uniswap.org/protocol/V1/guides/trade-tokens#deadlines
	/// @param payload allows for additional data when minting SToken
	function _swapEthAndStakeDev(
		uint256 amount,
		address property,
		uint256 deadline,
		bytes32 payload
	) internal virtual {
		uint256[] memory amounts = uniswapRouter.swapExactETHForTokens{
			value: amount
		}(1, _getPathForEthToDev(), address(this), deadline);
		IERC20(devAddress).approve(lockupAddress, amounts[1]);
		uint256 tokenId = ILockup(lockupAddress).depositToProperty(
			property,
			amounts[1],
			payload
		);
		IERC721(sTokensAddress).safeTransferFrom(
			address(this),
			msg.sender,
			tokenId
		);
	}
}
