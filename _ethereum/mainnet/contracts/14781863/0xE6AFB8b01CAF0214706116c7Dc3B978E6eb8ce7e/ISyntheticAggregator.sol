// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;
import "./LibDerivative.sol";

interface ISyntheticAggregator {
    struct SyntheticCache {
        uint256 buyerMargin;
        uint256 sellerMargin;
        uint256 authorCommission;
        address authorAddress;
        bool init;
    }

    function initialize(address _registry) external;

    function getOrCacheSyntheticCache(bytes32 _derivativeHash, LibDerivative.Derivative calldata _derivative)
        external
        returns (SyntheticCache memory);

    function getOrCacheMargin(bytes32 _derivativeHash, LibDerivative.Derivative calldata _derivative)
        external
        returns (uint256 buyerMargin, uint256 sellerMargin);
}
