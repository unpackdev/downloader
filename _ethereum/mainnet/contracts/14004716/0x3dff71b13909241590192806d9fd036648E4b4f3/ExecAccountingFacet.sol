// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./BFacetOwner.sol";
import "./LibExecAccounting.sol";
import "./LibExecAccess.sol";

contract ExecAccountingFacet is BFacetOwner {
    using LibExecAccounting for address;

    event LogSetGasMargin(uint256 oldGasMargin, uint256 newGasMargin);

    event LogSetMaxPriorityFee(
        uint256 oldMaxPriorityFee,
        uint256 newMaxPriorityFee
    );

    function setGasMargin(uint256 _gasMargin) external onlyOwner {
        emit LogSetGasMargin(gasMargin(), _gasMargin);
        LibExecAccess.setGasMargin(_gasMargin);
    }

    function setMaxPriorityFee(uint256 _maxPriorityFee) external onlyOwner {
        emit LogSetMaxPriorityFee(maxPriorityFee(), _maxPriorityFee);
        LibExecAccounting.setMaxPriorityFee(_maxPriorityFee);
    }

    function gasMargin() public view returns (uint256) {
        return LibExecAccess.gasMargin();
    }

    function maxPriorityFee() public view returns (uint256) {
        return LibExecAccounting.maxPriorityFee();
    }
}
