// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./BFacetOwner.sol";
import "./LibDiamond.sol";
import "./LibExecAccess.sol";

contract ExecAccessFlashbotsFacet is BFacetOwner {
    using LibDiamond for address;
    using LibExecAccess for address;

    // ################ Callable by Gov ################
    function addBundleExecutors(address[] calldata _bundleExecutors)
        external
        onlyOwner
    {
        for (uint256 i; i < _bundleExecutors.length; i++)
            require(
                _bundleExecutors[i].addBundleExecutor(),
                "ExecFacet.addBundleExecutors"
            );
    }

    function removeBundleExecutors(address[] calldata _bundleExecutors)
        external
    {
        for (uint256 i; i < _bundleExecutors.length; i++) {
            require(
                msg.sender == _bundleExecutors[i] ||
                    msg.sender.isContractOwner(),
                "ExecFacet.removeBundleExecutors: msg.sender ! bundleExecutor || owner"
            );
            require(
                _bundleExecutors[i].removeBundleExecutor(),
                "ExecFacet.removeBundleExecutors"
            );
        }
    }

    function isBundleExecutor(address _bundleExecutor)
        external
        view
        returns (bool)
    {
        return _bundleExecutor.isBundleExecutor();
    }

    function bundleExecutors() external view returns (address[] memory) {
        return LibExecAccess.bundleExecutors();
    }

    function numberOfBundleExecutors() external view returns (uint256) {
        return LibExecAccess.numberOfBundleExecutors();
    }
}
