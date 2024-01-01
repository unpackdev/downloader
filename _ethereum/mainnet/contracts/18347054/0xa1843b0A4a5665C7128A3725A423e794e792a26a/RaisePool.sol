// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.21;

import "./Ownable.sol";

/**
 * @title RaisePool
 * @notice This contract is designed to facilitate raising money for a cause. If the raise target is not hit,
 * all depositors will be entitled to a refund once the deadline is crossed. Raises can continue to happen after
 * the deadline has passed. A withdrawal can only take place if the target is reached.
 * @dev Overfunding can only occur in constructor payment. Target raise is in wei and deadline is in UNIX timestamp
 * @author Zodomo.eth (X: @0xZodomo, FC: @zodomo, Telegram: @zodomo, GitHub: Zodomo, Email: zodomo@proton.me)
 * @custom:github https://github.com/Zodomo/RaisePool
 */
contract RaisePool is Ownable {
    error Inactive(); // Raise target met and withdrawn
    error TargetMet(); // No further raises allowed
    error TargetNotMet(); // No withdrawals unless target is met
    error TransferFailed(); // ETH transfer from contract failed due to recipient error
    error DeadlineNotReached(); // No refunds until deadline is reached

    event Raise(address _sender, uint256 _amount);
    event Refund(address _sender, uint256 _amount);
    event Reached();
    event Withdraw();

    bool public active;
    uint256 public immutable target;
    uint256 public immutable deadline;
    mapping(address => uint256) public amounts;

    constructor(
        address _owner,
        uint256 _target,
        uint256 _deadline
    ) payable {
        _initializeOwner(_owner);
        if (msg.value > 0) {
            unchecked { amounts[msg.sender] += msg.value; }
        }
        target = _target;
        deadline = _deadline;
        active = true;
    }

    // Prevent raises once target is reached
    modifier isActive() {
        if (!active) { revert Inactive(); }
        _;
    }

    // Process raise payments and log all payors in order to handle refunds if necessary
    // Contract cannot raise over target, if last payor overpays, they'll get a rebate for the overage
    function raise() public payable isActive {
        if (address(this).balance - msg.value >= target) { revert TargetMet(); }
        uint256 overage;
        if (address(this).balance > target) {
            unchecked { overage = address(this).balance - target; }
            (bool success, ) = payable(msg.sender).call{ value: overage }("");
            if (!success) { revert TransferFailed(); }
            unchecked { amounts[msg.sender] += msg.value - overage; }
            emit Raise(msg.sender, msg.value - overage);
            emit Reached();
            return;
        }
        unchecked { amounts[msg.sender] += msg.value; }
        emit Raise(msg.sender, msg.value);
    }

    // After deadline is hit, if contract hasn't been withdrawn yet, allow depositors to get a refund
    function refund() external {
        if (block.timestamp < deadline) { revert DeadlineNotReached(); }
        uint256 amount = amounts[msg.sender];
        if (amount > 0) {
            delete amounts[msg.sender];
            (bool success, ) = payable(msg.sender).call{ value: amount }("");
            if (!success) { revert TransferFailed(); }
            emit Refund(msg.sender, amount);
        }
    }

    // Withdraw allowed once target is reached, this can take place after deadline if necessary
    function withdraw() external {
        if (address(this).balance < target) { revert TargetNotMet(); }
        (bool success, ) = payable(owner()).call{ value: address(this).balance }("");
        if (!success) { revert TransferFailed(); }
        emit Withdraw();
        active = false;
    }

    // Allow direct payments to be processed accordingly, no need to call raise() from etherscan
    receive() external payable { raise(); }
}
