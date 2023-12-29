// SPDX-License-Identifier: BSL
pragma solidity 0.8.19;

import "./Pausable.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

contract LaiSwap is Pausable, Ownable {
    using SafeERC20 for IERC20;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    address public immutable gpt;
    address public immutable lai;

    uint256 public totalSwapped;

    uint256 public startTime;
    uint256 public endTime;

    event Swapped(address indexed user, uint256 amount);
    event StartTimeChanged(uint256 fromTime, uint256 toTime);
    event EndTimeChanged(uint256 fromTime, uint256 toTime);

    constructor(
        address _gpt,
        address _lai,
        uint256 _startTime,
        uint256 _endTime
    ) {
        gpt = _gpt;
        lai = _lai;

        startTime = _startTime;
        endTime = _endTime;
    }

    modifier whenLive() {
        require(
            block.timestamp >= startTime && block.timestamp < endTime,
            "LaiSwap: not live"
        );
        _;
    }

    /**
     * @notice This function allows a user to swap their GPT tokens for LAI tokens.
     * @dev The function can only be called when the contract is not paused and during the live period.
     * @param amount The amount of GPT tokens the user wants to swap for LAI tokens.
     */
    function swap(uint256 amount) external whenNotPaused whenLive {
        require(amount > 0, "LaiSwap: amount must be greater than 0");

        totalSwapped += amount;

        IERC20(gpt).safeTransferFrom(msg.sender, DEAD, amount);
        IERC20(lai).safeTransfer(msg.sender, amount);

        emit Swapped(msg.sender, amount);
    }

    // Owner functions
    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        emit StartTimeChanged(startTime, _startTime);

        startTime = _startTime;
    }

    function setEndTime(uint256 _endTime) external onlyOwner {
        emit EndTimeChanged(endTime, _endTime);

        endTime = _endTime;
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}
