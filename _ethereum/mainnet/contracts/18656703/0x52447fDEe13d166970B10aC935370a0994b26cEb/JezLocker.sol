// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IDelegateRegistry.sol";

/// @title ChadLocker
/// @notice Token locker that has a delayed withdrawal period
/// @dev Inspired by the NChart LPLocker https://etherscan.io/address/0xe67b5f6f30760a4be273da49843ece74d13ae419#code
contract ChadLocker {
    uint256 public constant unlockLength = 90 days;
    IDelegateRegistry public immutable delegateRegistry;
    address public immutable tokenContract;

    address public owner;
    uint256 public lockUpEndTime;
    bool public isLiquidityLocked;
    bool public isWithdrawalTriggered;

    error CannotAssignOwnerToAddressZero();
    error LockupNotEnded();
    error ChadAlreadyLocked();
    error ChadNotLocked();
    error OnlyOwnerCanCall();
    error WithdrawalAlreadyTriggered();
    error WithdrawalNotTriggered();

    constructor(address tokenContract_, address delegateRegistry_, address owner_) {
        tokenContract = tokenContract_;
        owner = owner_;
        delegateRegistry = IDelegateRegistry(delegateRegistry_);
        delegateRegistry.delegateAll(owner_, bytes32(0), true);
    }

    function lockChad(uint256 amount) external {
        _requireIsOwner();

        if (isLiquidityLocked) {
            revert ChadAlreadyLocked();
        }

        IERC20(tokenContract).transferFrom(msg.sender, address(this), amount);

        isLiquidityLocked = true;
    }

    function triggerWithdrawal() external {
        _requireIsOwner();

        if (!isLiquidityLocked) {
            revert ChadNotLocked();
        }

        if (lockUpEndTime != 0) {
            revert WithdrawalAlreadyTriggered();
        }

        lockUpEndTime = block.timestamp + unlockLength;
        isWithdrawalTriggered = true;
    }

    function cancelWithdrawalTrigger() external {
        _requireIsOwner();

        if (!isLiquidityLocked) {
            revert ChadNotLocked();
        }

        if (lockUpEndTime == 0) {
            revert WithdrawalNotTriggered();
        }

        lockUpEndTime = 0;
        isWithdrawalTriggered = false;
    }

    function withdrawChad(uint256 amount) external {
        _requireIsOwner();

        if (!isLiquidityLocked) {
            revert ChadNotLocked();
        }
        if (lockUpEndTime == 0) {
            revert WithdrawalNotTriggered();
        }
        if (block.timestamp < lockUpEndTime) {
            revert LockupNotEnded();
        }

        IERC20(tokenContract).transfer(owner, amount);

        isLiquidityLocked = false;
        lockUpEndTime = 0;
        isWithdrawalTriggered = false;
    }

    function changeOwner(address newOwner) external {
        _requireIsOwner();
        if (newOwner == address(0)) {
            revert CannotAssignOwnerToAddressZero();
        }
        owner = newOwner;
    }

    function setDelegate(address newDelegate) external {
        _requireIsOwner();
        delegateRegistry.delegateAll(newDelegate, bytes32(0), true);
    }

    function _requireIsOwner() internal view {
        if (msg.sender != owner) {
            revert OnlyOwnerCanCall();
        }
    }
}
