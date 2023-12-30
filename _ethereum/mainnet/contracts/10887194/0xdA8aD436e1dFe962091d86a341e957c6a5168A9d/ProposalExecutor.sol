pragma solidity ^0.5.16;

import "./IProposalExecutor.sol";
import "./LendingPoolAddressesProvider.sol";

contract ProposalExecutor is IProposalExecutor {

    event ProposalExecuted(
        address indexed executor,
        address indexed lendingPoolAddressesProvider,
        address indexed newAddress
    );

    /// @notice Fallback function, not allowing transfer of ETH
    function() external payable {
        revert("ETH_TRANSFER_NOT_ALLOWED");
    }

    function execute() external {
        // Hardcoded address because of the determinism on buidlerevm
        address _addressesProvider = 0x7c2C195CD6D34B8F845992d380aADB2730bB9C6F;
        address _newLendingPoolManager = 0x0000000000000000000000000000000000000001;
        LendingPoolAddressesProvider(_addressesProvider).setLendingPoolManager(_newLendingPoolManager);
        emit ProposalExecuted(address(this), _addressesProvider, _newLendingPoolManager);
    }

}