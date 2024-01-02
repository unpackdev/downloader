// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "./ReentrancyGuard.sol";
import "./NativeOwnerApproval.sol";

// WagerBet Custodial
contract ClaimETH is NativeOwnerApproval, ReentrancyGuard {
    /* ========== EVENTS ========== */
    event Withdraw(uint256 amount);
    event ETHClaimed(uint256 indexed nonce, address indexed user, uint256 amount);
    event EtherDeposited(address indexed from, uint256 amount);

    constructor() {
        _initializeEIP712('ClaimETH', '1');
    }

    receive() external payable {
        emit EtherDeposited(msg.sender, msg.value);
    }

    function claimETHByUser(uint256 amount, uint256 deadline, bytes32 sigR, bytes32 sigS, uint8 sigV) external nonReentrant {
        require(block.timestamp <= deadline, 'Withdrawal Time Limit Elapsed');
        checkOwnerApproval(abi.encode(msg.sender, amount, deadline), sigR, sigS, sigV);
        _withdrawEther(msg.sender, amount);
        emit ETHClaimed(nonces[msg.sender] - 1, msg.sender, amount);
    }

    function withdrawEther(uint256 amount) external onlyOwner nonReentrant {
        _withdrawEther(msg.sender, amount);
        emit Withdraw(amount);
    }

    function _withdrawEther(address user, uint256 amount) internal {
        (bool sent, bytes memory data) = payable(user).call{value: amount}('');
        string memory response = string(data);
        require(sent, response);
    }
}
