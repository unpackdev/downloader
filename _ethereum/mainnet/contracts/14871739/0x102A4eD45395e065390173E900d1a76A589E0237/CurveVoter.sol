// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./CurveStrategy.sol";

contract CurveVoter {
	address public curveStrategy = 0x20F1d4Fed24073a9b9d388AfA2735Ac91f079ED6;
	address public constant crvLocker = 0x52f541764E6e90eeBc5c21Ff570De0e2D63766B6;
	address public constant curveGaugeController = 0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB;
	address public constant curveVoting = 0xE478de485ad2fe566d49342Cbd03E49ed7DB3356;
	address governance;

	constructor() {
		governance = msg.sender;
	}

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

	function votePct(
		uint256 _voteId,
		uint256 _yeaPct,
		uint256 _nayPct
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
			abi.encodeWithSignature("execute(address,uint256,bytes)", curveVoting, 0, voteData)
		);
		require(success, "Voting failed!");
	}

	function vote(uint256 _voteData, bool _supports) external {
		require(msg.sender == governance, "!governance");
		bytes memory voteData = abi.encodeWithSignature("vote(uint256,bool,bool)", _voteData, _supports, false);
		bytes memory executeData = abi.encodeWithSignature("execute(address,uint256,bytes)", curveVoting, 0, voteData);
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
