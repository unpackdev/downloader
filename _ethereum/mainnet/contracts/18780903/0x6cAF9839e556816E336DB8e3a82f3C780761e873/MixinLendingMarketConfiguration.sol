// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// interfaces
import "./ILendingMarket.sol";
// utils
import "./Ownable.sol";
// storages
import "./LendingMarketControllerStorage.sol";

contract MixinLendingMarketConfiguration is Ownable {
    function _initialize(address _owner) internal {
        _transferOwnership(_owner);
    }

    /**
     * @notice Gets the order fee rate
     * @param _ccy Currency name in bytes32
     * @return The order fee rate received by protocol
     */
    function getOrderFeeRate(bytes32 _ccy) public view returns (uint256) {
        return ILendingMarket(Storage.slot().lendingMarkets[_ccy]).getOrderFeeRate();
    }

    /**
     * @notice Gets the limit range in unit price for the circuit breaker
     * @param _ccy Currency name in bytes32
     * @return The auto-roll fee rate received by protocol
     */
    function getCircuitBreakerLimitRange(bytes32 _ccy) public view returns (uint256) {
        return ILendingMarket(Storage.slot().lendingMarkets[_ccy]).getCircuitBreakerLimitRange();
    }

    /**
     * @notice Updates the order fee rate
     * @param _ccy Currency name in bytes32
     * @param _orderFeeRate The order fee rate received by protocol
     */
    function updateOrderFeeRate(bytes32 _ccy, uint256 _orderFeeRate) public onlyOwner {
        ILendingMarket(Storage.slot().lendingMarkets[_ccy]).updateOrderFeeRate(_orderFeeRate);
    }

    /**
     * @notice Updates the auto-roll fee rate
     * @param _ccy Currency name in bytes32
     * @param _cbLimitRange The circuit breaker limit range
     */
    function updateCircuitBreakerLimitRange(bytes32 _ccy, uint256 _cbLimitRange) public onlyOwner {
        ILendingMarket(Storage.slot().lendingMarkets[_ccy]).updateCircuitBreakerLimitRange(
            _cbLimitRange
        );
    }
}
