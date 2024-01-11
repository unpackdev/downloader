// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./Owner.sol";
import "./SafeERC20.sol";

/** @title Paladin Reward Reserve contract  */
/// @author Paladin
contract PaladinRewardReserve is Owner, ReentrancyGuard{
    using SafeERC20 for IERC20;

    /** @notice Addresses allowed to transfer tokens from this contract */
    // User => token => bool
    mapping(address => mapping(address => bool)) public approvedSpenders;

    /** @notice Emitted when a new spender is approved*/
    event NewSpender(address indexed token, address indexed spender, uint256 amount);
    /** @notice Emitted when the allowance of a spander is updated */
    event UpdateSpender(address indexed token, address indexed spender, uint256 amount);
    /** @notice Emitted when a spender allowance is removed */
    event RemovedSpender(address indexed token, address indexed spender);

    event TokenTransfer(address indexed token, address indexed receiver, uint256 amount);

    constructor(address _admin) {
        _transferOwnership(_admin);
    }

    function setNewSpender(address token, address spender, uint256 amount) external nonReentrant onlyOwner {
        require(!approvedSpenders[spender][token], "Already Spender");
        approvedSpenders[spender][token] = true;
        IERC20(token).safeIncreaseAllowance(spender, amount);

        emit NewSpender(token, spender, amount);
    }

    function updateSpenderAllowance(address token, address spender, uint256 amount) external nonReentrant onlyOwner {
        require(approvedSpenders[spender][token], "Not approved Spender");
        uint256 currentAllowance = IERC20(token).allowance(address(this), spender);

        if(currentAllowance < amount){
            IERC20(token).safeIncreaseAllowance(spender, amount - currentAllowance);
        }
        else if(currentAllowance > amount){
            IERC20(token).safeDecreaseAllowance(spender, currentAllowance - amount);
        }
        // Otherwise, allowance is already the required value, no need to change

        emit UpdateSpender(token, spender, amount);
    }

    function removeSpender(address token, address spender) external nonReentrant onlyOwner {
        require(approvedSpenders[spender][token], "Not approved Spender");
        approvedSpenders[spender][token] = false;
        uint256 currentAllowance = IERC20(token).allowance(address(this), spender);
        if(currentAllowance != 0){
            IERC20(token).safeDecreaseAllowance(spender, currentAllowance);
        }

        emit RemovedSpender(token, spender);
    }

    function transferToken(address token, address receiver, uint256 amount) external nonReentrant onlyOwner {
        IERC20(token).safeTransfer(receiver, amount);

        emit TokenTransfer(token, receiver, amount);
    }

}
