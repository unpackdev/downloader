pragma solidity ^0.7.0;

/**
 * @title Stake Eth.
 * @dev deposit Eth into lido and in return you get equivalent of stEth tokens
 */

import "./math.sol";
import "./basic.sol";
import "./events.sol";
import "./helpers.sol";

abstract contract Resolver is Events, DSMath, Basic, Helpers {
	/**
	 * @dev deposit ETH into Lido.
	 * @notice sends Eth into lido and in return you get equivalent of stEth tokens
	 * @param amt The amount of ETH to deposit. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of ETH deposited.
	 */
	function deposit(
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		_amt = _amt == uint256(-1) ? address(this).balance : _amt;
		lidoInterface.submit{ value: amt }(treasury);
		setUint(setId, _amt);

		_eventName = "LogDeposit(uint256,uint256,uint256)";
		_eventParam = abi.encode(_amt, getId, setId);
	}
}

contract ConnectV2LidoStEth is Resolver {
	string public constant name = "LidoStEth-v1";
}
