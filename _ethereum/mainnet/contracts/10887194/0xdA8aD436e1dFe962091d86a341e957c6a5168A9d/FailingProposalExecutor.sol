pragma solidity ^0.5.16;

import "./IProposalExecutor.sol";

contract FailingProposalExecutor is IProposalExecutor {

    /// @notice Fallback function, not allowing transfer of ETH
    function() external payable {
        revert("ETH_TRANSFER_NOT_ALLOWED");
    }

    function execute() external {
        require(false, "FORCED_REVERT");
    }

}