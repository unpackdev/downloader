// SPDX-License-Identifier: BSL
pragma solidity 0.8.19;

import "./Pausable.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

contract LaiSwapV2 is Pausable, Ownable {
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

    struct MonitoredAddress {
        address _address;
        uint256 _amount;
    }
    MonitoredAddress public monitoredBalance;
    MonitoredAddress public monitoredSupply;

    event MonitoredBalanceChanged(
        address indexed fromAddress,
        address indexed toAddress,
        uint256 fromAmount,
        uint256 toAmount
    );

    event MonitoredSupplyChanged(
        address indexed fromAddress,
        address indexed toAddress,
        uint256 fromAmount,
        uint256 toAmount
    );

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
     * @notice This modifier checks if the total supply of GPT tokens mathces the monitored amount.
     * @dev The modifier is only relevant if the monitored address is set.
     */
    modifier ensureMonitoredSupply() {
        (address address_, uint256 amount_) = (
            monitoredSupply._address,
            monitoredSupply._amount
        );
        if (address_ == address(0)) {
            _;
        } else {
            require(
                IERC20(address_).totalSupply() == amount_,
                "LaiSwap: monitored supply mismatch"
            );
            _;
        }
    }

    /**
     * @notice This modifier checks if the monitored address has the monitored amount of GPT tokens.
     * @dev The modifier is only relevant if the monitored address is set.
     */
    modifier ensureMonitoredBalance() {
        (address address_, uint256 amount_) = (
            monitoredBalance._address,
            monitoredBalance._amount
        );

        if (address_ == address(0)) {
            _;
        } else {
            require(
                IERC20(gpt).balanceOf(address_) == amount_,
                "LaiSwap: monitored balance mismatch"
            );
            _;
        }
    }

    /**
     * @notice This function allows a user to swap their GPT tokens for LAI tokens.
     * @dev The function can only be called when the contract is not paused and during the live period.
     * Additionally, it requires the monitored address to have the monitored amount of GPT tokens.
     * @param amount The amount of GPT tokens the user wants to swap for LAI tokens.
     */
    function swap(
        uint256 amount
    )
        external
        whenNotPaused
        whenLive
        ensureMonitoredSupply
        ensureMonitoredBalance
    {
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

    function setTimes(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(
            _startTime != startTime || _endTime != endTime,
            "LaiSwap: no time changes"
        );

        if (_startTime != startTime) {
            emit StartTimeChanged(startTime, _startTime);
            startTime = _startTime;
        }

        if (_endTime != endTime) {
            emit EndTimeChanged(endTime, _endTime);
            endTime = _endTime;
        }
    }

    function setMonitoredBalance(
        address _address,
        uint256 _amount
    ) external onlyOwner {
        emit MonitoredBalanceChanged(
            monitoredBalance._address,
            _address,
            monitoredBalance._amount,
            _amount
        );

        monitoredBalance = MonitoredAddress(_address, _amount);
    }

    function setMonitoredSupply(
        address _address,
        uint256 _amount
    ) external onlyOwner {
        emit MonitoredSupplyChanged(
            monitoredSupply._address,
            _address,
            monitoredSupply._amount,
            _amount
        );

        monitoredSupply = MonitoredAddress(_address, _amount);
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}
