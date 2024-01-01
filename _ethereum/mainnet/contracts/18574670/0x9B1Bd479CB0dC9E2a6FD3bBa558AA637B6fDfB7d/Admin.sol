// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";

abstract contract Admin is Initializable {
    address public poolManager;
    address public bridgeManager;
    address public bridgeReviewer; // When bridgeReviewer == bridgeManager, the reviewing step will be skipped.

    // Two-step ownership management design, similar to Ownable2Step in OpenZeppelin Contracts.
    address public pendingPoolManager;
    address public pendingBridgeManager;
    address public pendingBridgeReviewer;

    event PoolManagerTransferStarted(address indexed previousOwner, address indexed newOwner);
    event PoolManagerTransferred(address indexed previousOwner, address indexed newOwner);

    event BridgeManagerTransferStarted(address indexed previousOwner, address indexed newOwner);
    event BridgeManagerTransferred(address indexed previousOwner, address indexed newOwner);

    event BridgeReviewerTransferStarted(address indexed previousOwner, address indexed newOwner);
    event BridgeReviewerTransferred(address indexed previousOwner, address indexed newOwner);

    function __Admin_init() internal onlyInitializing {
        poolManager = msg.sender;
        bridgeManager = msg.sender;
        bridgeReviewer = msg.sender;
    }

    modifier onlyPoolManager() {
        require(msg.sender == poolManager, "Admin: caller is not poolManager");
        _;
    }

    modifier onlyBridgeManager() {
        require(msg.sender == bridgeManager, "Admin: caller is not bridgeManager");
        _;
    }

    modifier onlyBridgeReviewer() {
        require(msg.sender == bridgeReviewer, "Admin: caller is not bridgeReviewer");
        _;
    }

    function transferPoolManager(address newOwner) external onlyPoolManager {
        pendingPoolManager = newOwner;
        emit PoolManagerTransferStarted(msg.sender, newOwner);
    }

    function acceptPoolManager() external {
        require(msg.sender == pendingPoolManager, "Admin: caller is not the new owner");
        delete pendingPoolManager;
        address oldOwner = poolManager;
        poolManager = msg.sender;
        emit PoolManagerTransferred(oldOwner, msg.sender);
    }

    function transferBridgeManager(address newOwner) external onlyBridgeManager {
        pendingBridgeManager = newOwner;
        emit BridgeManagerTransferStarted(msg.sender, newOwner);
    }

    function acceptBridgeManager() external {
        require(msg.sender == pendingBridgeManager, "Admin: caller is not the new owner");
        delete pendingBridgeManager;
        address oldOwner = bridgeManager;
        bridgeManager = msg.sender;
        emit BridgeManagerTransferred(oldOwner, msg.sender);
    }

    function transferBridgeReviewer(address newOwner) external onlyBridgeReviewer {
        pendingBridgeReviewer = newOwner;
        emit BridgeReviewerTransferStarted(msg.sender, newOwner);
    }

    function acceptBridgeReviewer() external {
        require(msg.sender == pendingBridgeReviewer, "Admin: caller is not the new owner");
        delete pendingBridgeReviewer;
        address oldOwner = bridgeReviewer;
        bridgeReviewer = msg.sender;
        emit BridgeReviewerTransferred(oldOwner, msg.sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}
