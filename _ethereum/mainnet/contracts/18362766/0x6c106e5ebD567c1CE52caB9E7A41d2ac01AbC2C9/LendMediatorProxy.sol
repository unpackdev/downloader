// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Proxy.sol";
import "./LendMediatorStorage.sol";
import "./LendManager.sol";
import "./LendMediatorInterface.sol";
import "./DetectContract.sol";

/**
 * @title MetaLend's LendMediatorProxy Contract
 * @author MetaLend
 * @notice Each user has one mediator proxy contract
 * @dev Proxies to LendMediator implementation
 */
contract LendMediatorProxy is Proxy, LendMediatorProxyInterface, LendMediatorProxyStorage {
    /**
     * @notice Construct the mediator contract
     * @dev msg.sender is LendManager
     * @param newOwner The owner of the mediator contract (user)
     */
    constructor(address payable newOwner) {
        if (!DetectContract.isExistingContract(msg.sender)) {
            revert ErrCallerNotLendManager(msg.sender);
        }
        try LendManager(msg.sender).IS_LEND_MANAGER() returns (bool isLendManager) {
            if (!isLendManager) {
                revert ErrCallerNotLendManager(msg.sender);
            }
        } catch {
            revert ErrCallerNotLendManager(msg.sender);
        }
        if (newOwner == address(0)) revert ErrInvalidAddress(newOwner);
        lendManager = LendManager(msg.sender);
        owner = newOwner;
        emit NewLendManager(msg.sender);
        emit NewOwner(newOwner);
    }

    /**
     * @notice this function returns mediator implementation held at manager
     * @return address of the implementation
     */
    function _implementation() internal view override returns (address) {
        address implementation = lendManager.lendMediatorImplementation();
        if (implementation == address(0)) revert ErrInvalidAddress(implementation);
        return implementation;
    }
}
