// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import "./GovernorEvents.sol";
import "./GovernorStorage.sol";


/// @title GovernorProxy (delegator) smart contract
/// @author D-ETF.com
/// @notice Proxy implementation of the Governor smart contract.
/// @dev The contract uses the shared storage contract (GovernorStorage) and allows to do logic updates.
contract GovernorProxy is GovernorStorage, GovernorEvents {

    //  --------------------
    //  CONSTRUCTOR
    //  --------------------


	constructor(
        address timelock_,
        address detf_,
        address admin_,
        address implementation_,
        uint256 votingPeriod_,
        uint256 votingDelay_,
        uint256 proposalThreshold_
    ) {
        // Admin set to msg.sender for initialization
        admin = msg.sender;

        _delegateTo(
            implementation_,
            abi.encodeWithSignature(
                "initialize(address,address,uint256,uint256,uint256)",
                timelock_,
                detf_,
                votingPeriod_,
                votingDelay_,
                proposalThreshold_
            )
        );

        setImplementation(implementation_);

		admin = admin_;
	}

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable {
        _fallback();
    }


    //  --------------------
    //  INTERNAL
    //  --------------------


	/**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     */
    function setImplementation(address implementation_) public {
        require(msg.sender == admin, "setImplementation: Admin only.");
        require(implementation_ != address(0), "setImplementation: Invalid implementation address.");

        address oldImplementation = implementation;
        implementation = implementation_;

        emit NewImplementation(oldImplementation, implementation);
    }


    //  --------------------
    //  INTERNAL
    //  --------------------


    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     */
    function _delegateTo(address callee, bytes memory data) internal {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
    }

	/**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    function _fallback() internal {
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }
}