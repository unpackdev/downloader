// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./ICentaurFactory.sol";
import "./ICentaurPool.sol";
import "./ICentaurSettlement.sol";

contract CentaurSettlement is ICentaurSettlement {

	using SafeMath for uint;

	bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

	address public override factory;
	uint public override settlementDuration;

	// User address -> Token address -> Settlement
	mapping(address => mapping (address => Settlement)) pendingSettlement;

	modifier onlyFactory() {
        require(msg.sender == factory, 'CentaurSwap: ONLY_FACTORY_ALLOWED');
        _;
    }

	constructor (address _factory, uint _settlementDuration) public {
		factory = _factory;
		settlementDuration = _settlementDuration;
	}

	function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'CentaurSwap: TRANSFER_FAILED');
    }

	function addSettlement(
		address _sender,
		Settlement memory _pendingSettlement
	) external override {
		require(ICentaurFactory(factory).isValidPool(_pendingSettlement.fPool), 'CentaurSwap: POOL_NOT_FOUND');
		require(ICentaurFactory(factory).isValidPool(_pendingSettlement.tPool), 'CentaurSwap: POOL_NOT_FOUND');

		require(msg.sender == _pendingSettlement.tPool, 'CentaurSwap: INVALID_POOL');

		require(pendingSettlement[_sender][_pendingSettlement.fPool].settlementTimestamp == 0, 'CentaurSwap: SETTLEMENT_EXISTS');
		require(pendingSettlement[_sender][_pendingSettlement.tPool].settlementTimestamp == 0, 'CentaurSwap: SETTLEMENT_EXISTS');

		pendingSettlement[_sender][_pendingSettlement.fPool] = _pendingSettlement;
		pendingSettlement[_sender][_pendingSettlement.tPool] = _pendingSettlement;

	}

	function removeSettlement(
		address _sender,
		address _fPool,
		address _tPool
	) external override {
		require(msg.sender == _tPool, 'CentaurSwap: INVALID_POOL');

		require(pendingSettlement[_sender][_fPool].settlementTimestamp != 0, 'CentaurSwap: SETTLEMENT_DOES_NOT_EXISTS');
		require(pendingSettlement[_sender][_tPool].settlementTimestamp != 0, 'CentaurSwap: SETTLEMENT_DOES_NOT_EXISTS');

		require(block.timestamp >= pendingSettlement[_sender][_fPool].settlementTimestamp, 'CentaurSwap: SETTLEMENT_PENDING');

		_safeTransfer(ICentaurPool(_tPool).baseToken(), _tPool, pendingSettlement[_sender][_fPool].maxAmountOut);

		delete pendingSettlement[_sender][_fPool];
		delete pendingSettlement[_sender][_tPool];
	}

	function getPendingSettlement(address _sender, address _pool) external override view returns (Settlement memory) {
		return pendingSettlement[_sender][_pool];
	}
	
	function hasPendingSettlement(address _sender, address _pool) external override view returns (bool) {
		return (pendingSettlement[_sender][_pool].settlementTimestamp != 0);
	}

	// Helper Functions
	function setSettlementDuration(uint _settlementDuration) onlyFactory external override {
		settlementDuration = _settlementDuration;
	}
}