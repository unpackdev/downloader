// SPDX-License-Identifier: MIT
pragma solidity =0.6.11;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IxFOX.sol";


contract FoxLock {
    using SafeMath for uint256;

    uint256 constant public lockDuration = 7 days;

    IERC20 public foxToken;
    address public xFOX;

    mapping(address => uint256) public unlocking;
    mapping(address => uint256) public unlockTime;

    // --- Events ---
    event Lock(address account, uint256 amount, uint256 unlockTime);
    event Reenter(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);

    // --- Modifier ---
    modifier validCaller() {
        require(msg.sender == xFOX, "FoxLock: caller is not xFOX");
        _;
    }

    // --- Constructor ---
    constructor (address _foxToken, address _xFOX) public {
        foxToken = IERC20(_foxToken);
        xFOX = _xFOX;
    }

    // --- Functions ---
    function lock(address _account, uint256 _amount) external validCaller {
        unlocking[_account] = unlocking[_account].add(_amount);

        uint256 accountUnlockTime = block.timestamp.add(lockDuration);
        unlockTime[_account] = accountUnlockTime;

        emit Lock(_account, _amount, accountUnlockTime);
    }

    function reenter() external {
        uint256 reenterAmount = unlocking[msg.sender];
        require(reenterAmount > 0, "FoxLock: need non zero reenter amount");
        unlocking[msg.sender] = 0;

        foxToken.approve(xFOX, reenterAmount);
        IxFOX(xFOX).enter(msg.sender, reenterAmount);

        emit Reenter(msg.sender, reenterAmount);
    }

    function withdraw() external {
        require(block.timestamp >= unlockTime[msg.sender], "FoxLock: the lockup period has not expired");

        uint256 withdrawAmount = unlocking[msg.sender];
        require(withdrawAmount > 0, "FoxLock: cannot withdraw 0");
        unlocking[msg.sender] = 0;

        foxToken.transfer(msg.sender, withdrawAmount);
        emit Withdraw(msg.sender, withdrawAmount);
    }
}