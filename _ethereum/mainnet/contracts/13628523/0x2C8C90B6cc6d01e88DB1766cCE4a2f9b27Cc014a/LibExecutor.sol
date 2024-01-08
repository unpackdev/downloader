// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./EnumerableSet.sol";

library LibExecutor {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct ExecutorStorage {
        EnumerableSet.AddressSet executors;
        uint256 gasMargin;
        EnumerableSet.AddressSet bundleExecutors;
    }

    bytes32 private constant _EXECUTOR_STORAGE_POSITION =
        keccak256("gelato.diamond.executor.storage");

    function addExecutor(address _executor) internal returns (bool) {
        return executorStorage().executors.add(_executor);
    }

    function addBundleExecutor(address _bundleExecutor)
        internal
        returns (bool)
    {
        return executorStorage().bundleExecutors.add(_bundleExecutor);
    }

    function removeExecutor(address _executor) internal returns (bool) {
        return executorStorage().executors.remove(_executor);
    }

    function removeBundleExecutor(address _bundleExecutor)
        internal
        returns (bool)
    {
        return executorStorage().bundleExecutors.remove(_bundleExecutor);
    }

    function setGasMargin(uint256 _gasMargin) internal {
        executorStorage().gasMargin = _gasMargin;
    }

    function canExec(address _executor) internal view returns (bool) {
        return isExecutor(_executor);
    }

    function isExecutor(address _executor) internal view returns (bool) {
        return executorStorage().executors.contains(_executor);
    }

    function isBundleExecutor(address _bundleExecutor)
        internal
        view
        returns (bool)
    {
        return executorStorage().bundleExecutors.contains(_bundleExecutor);
    }

    function executorAt(uint256 _index) internal view returns (address) {
        return executorStorage().executors.at(_index);
    }

    function bundleExecutorAt(uint256 _index) internal view returns (address) {
        return executorStorage().bundleExecutors.at(_index);
    }

    function executors() internal view returns (address[] memory executors_) {
        uint256 length = numberOfExecutors();
        executors_ = new address[](length);
        for (uint256 i; i < length; i++) executors_[i] = executorAt(i);
    }

    function bundleExecutors()
        internal
        view
        returns (address[] memory bundleExecutors_)
    {
        uint256 length = numberOfBundleExecutors();
        bundleExecutors_ = new address[](length);
        for (uint256 i; i < length; i++)
            bundleExecutors_[i] = bundleExecutorAt(i);
    }

    function numberOfExecutors() internal view returns (uint256) {
        return executorStorage().executors.length();
    }

    function numberOfBundleExecutors() internal view returns (uint256) {
        return executorStorage().bundleExecutors.length();
    }

    function gasMargin() internal view returns (uint256) {
        return executorStorage().gasMargin;
    }

    function executorStorage()
        internal
        pure
        returns (ExecutorStorage storage es)
    {
        bytes32 position = _EXECUTOR_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}
