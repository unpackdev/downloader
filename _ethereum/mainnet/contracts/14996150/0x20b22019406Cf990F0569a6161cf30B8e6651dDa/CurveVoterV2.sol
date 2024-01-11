// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./CurveStrategy.sol";

contract CurveVoterV2 {
	address public curveStrategy = 0x20F1d4Fed24073a9b9d388AfA2735Ac91f079ED6;
	address public constant crvLocker = 0x52f541764E6e90eeBc5c21Ff570De0e2D63766B6;
	address public constant curveGaugeController = 0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB;
	address public governance = 0xF930EBBd05eF8b25B1797b9b2109DDC9B0d43063;

	constructor() {}

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
			(bool success, ) = CurveStrategy(curveStrategy).execute(
				crvLocker,
				0,
				abi.encodeWithSignature("execute(address,uint256,bytes)", curveGaugeController, 0, voteData)
			);
			require(success, "Voting failed!");
		}
	}

	/// @notice votePct function for the voting on the curve onchain proposals
	/// @param _voteId id of the vote
	/// @param _yeaPct percentage of yes votes
	/// @param _nayPct percentage of no votes
	/// @param _curveVoting address of the related curve voting contract
	function votePct(
		uint256 _voteId,
		uint256 _yeaPct,
		uint256 _nayPct,
		address _curveVoting
	) external {
		require(msg.sender == governance, "!governance");
		bytes memory voteData = abi.encodeWithSignature(
			"votePct(uint256,uint256,uint256,bool)",
			_voteId,
			_yeaPct,
			_nayPct,
			false
		);
		(bool success, ) = CurveStrategy(curveStrategy).execute(
			crvLocker,
			0,
			abi.encodeWithSignature("execute(address,uint256,bytes)", _curveVoting, 0, voteData)
		);
		require(success, "Voting failed!");
	}

	/// @notice vote function for the voting on the curve onchain proposals
	/// @param _voteData id of the vote
	/// @param _supports if supports the proposal or not
	/// @param _curveVoting address of the related curve voting contract
	function vote(
		uint256 _voteData,
		bool _supports,
		address _curveVoting
	) external {
		require(msg.sender == governance, "!governance");
		bytes memory voteData = abi.encodeWithSignature("vote(uint256,bool,bool)", _voteData, _supports, false);
		bytes memory executeData = abi.encodeWithSignature("execute(address,uint256,bytes)", _curveVoting, 0, voteData);
		(bool success, ) = CurveStrategy(curveStrategy).execute(crvLocker, 0, executeData);
		require(success, "Voting failed!");
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
		uint256 tokenBalance = IERC20(_token).balanceOf(crvLocker);
		bytes memory transferData = abi.encodeWithSignature("transfer(address,uint256)", _recipient, tokenBalance);
		bytes memory executeData = abi.encodeWithSignature("execute(address,uint256,bytes)", _token, 0, transferData);
		(success, ) = CurveStrategy(curveStrategy).execute(crvLocker, 0, executeData);
		require(success, "transfer failed");
		return (success, result);
	}

	/* ========== SETTERS ========== */
	function setGovernance(address _newGovernance) external {
		require(msg.sender == governance, "!governance");
		governance = _newGovernance;
	}

	function changeStrategy(address _newStrategy) external {
		require(msg.sender == governance, "!governance");
		curveStrategy = _newStrategy;
	}
}
