// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./FxsLocker.sol";
import "./FraxStrategy.sol";

contract FraxVoter {
	address public constant FXS_LOCKER = 0xCd3a267DE09196C48bbB1d9e842D7D7645cE448f;
	address public constant FXS_GAUGE_CONTROLLER = 0x3669C421b77340B2979d1A00a792CC2ee0FcE737;
	address public constant FRAX_STRATEGY = 0xf285Dec3217E779353350443fC276c07D05917c3;
	address public governance;

	constructor() {
		governance = msg.sender;
	}

	/// @notice vote for frax gauges
	/// @param _gauges gauges to vote for
	/// @param _weights vote weight for each gauge
	function voteGauges(address[] calldata _gauges, uint256[] calldata _weights) external {
		require(msg.sender == governance, "!governance");
		require(_gauges.length == _weights.length, "!length");
		uint256 length = _gauges.length;
		for (uint256 i; i < length; i++) {
			bytes memory voteData = abi.encodeWithSignature(
				"vote_for_gauge_weights(address,uint256)",
				_gauges[i],
				_weights[i]
			);
			bytes memory executeData = abi.encodeWithSignature(
				"execute(address,uint256,bytes)",
				FXS_GAUGE_CONTROLLER,
				0,
				voteData
			);
			(bool success, ) = FraxStrategy(FRAX_STRATEGY).execute(FXS_LOCKER, 0, executeData);
			require(success, "Voting failed!");
		}
	}

	/// @notice execute a function
	/// @param _to Address to sent the value to
	/// @param _value Value to be sent
	/// @param _data Call function data
	function execute(
		address _to,
		uint256 _value,
		bytes calldata _data
	) external returns (bool, bytes memory) {
		require(msg.sender == governance, "!governance");
		(bool success, bytes memory result) = _to.call{ value: _value }(_data);
		return (success, result);
	}

	/// @notice execute a function and transfer funds to the given address
	/// @param _to Address to sent the value to
	/// @param _value Value to be sent
	/// @param _data Call function data
	/// @param _token address of the token that we will transfer
	/// @param _recipient address of the recipient that will get the tokens
	function executeAndTransfer(
		address _to,
		uint256 _value,
		bytes calldata _data,
		address _token,
		address _recipient
	) external returns (bool, bytes memory) {
		require(msg.sender == governance, "!governance");
		(bool success, bytes memory result) = _to.call{ value: _value }(_data);
		require(success, "!success");
		uint256 tokenBalance = IERC20(_token).balanceOf(FXS_LOCKER);
		bytes memory transferData = abi.encodeWithSignature("transfer(address,uint256)", _recipient, tokenBalance);
		bytes memory executeData = abi.encodeWithSignature("execute(address,uint256,bytes)", _token, 0, transferData);
		(success, ) = FraxStrategy(FRAX_STRATEGY).execute(FXS_LOCKER, 0, executeData);
		require(success, "transfer failed");
		return (success, result);
	}

	/* ========== SETTERS ========== */
	/// @notice set new governance
	/// @param _newGovernance governance address
	function setGovernance(address _newGovernance) external {
		require(msg.sender == governance, "!governance");
		governance = _newGovernance;
	}
}
