// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

import "./GROBaseVester.sol";

/// @notice Vesting contract for Grwth labs - This vesting contract is responsible for
///     distributing assets assigned to Grwth labs by the GRO DAO. This contract can:
///         - Create vesting positions for individual employees
///         - Stop employees vesting positions, leaving what has already vested as available
///             to be claimed by the employee, but removes and unvested assets from the position
///         - Claim excess tokens directly, excess tokens being defined as tokens that have been
///             vested globally, but hasnt beens assigned to an employees vesting position.
contract GROEmpVesting is GROBaseVesting {
    struct EmployeePosition {
        uint256 total;
        uint256 withdrawn;
        uint256 startTime;
        uint256 stopTime;
    }

    mapping(address => EmployeePosition) public employeePositions;

    event LogNewVest(address indexed employee, uint256 amount);
    event LogClaimed(address indexed employee, uint256 amount, uint256 withdrawn, uint256 available);
    event LogWithdrawal(address account, uint256 amount);
    event LogStoppedVesting(address indexed employee, uint256 unlocked, uint256 available);

    constructor(uint256 startTime, uint256 quota) GROBaseVesting(startTime, quota) {}

    /// @notice Creates a vesting position
    /// @param account Account which to add vesting position for
    /// @param startTime when the positon should start
    /// @param amount Amount to add to vesting position
    /// @dev The startstime paramter allows some leeway when creating
    ///     positions for new employees
    function vest(address account, uint256 startTime, uint256 amount) external override onlyOwner {
        require(account != address(0), "vest: !account");
        require(amount > 0, "vest: !amount");
        if (startTime + START_TIME_LOWER_BOUND < block.timestamp) {
            startTime = block.timestamp;
        }

        EmployeePosition storage ep = employeePositions[account];

        require(ep.startTime == 0, 'vest: position already exists');
        ep.startTime = startTime;
        require((QUOTA - vestingAssets) >= amount, 'vest: not enough assets available');
        ep.total = amount;
        vestingAssets += amount;

        emit LogNewVest(account, amount);
    }

    /// @notice owner can withdraw excess tokens
    /// @param amount amount to be withdrawns
    function withdraw(uint256 amount) external onlyOwner {
        ( , , uint256 available ) = globallyUnlocked();
        require(amount <= available, 'withdraw: not enough assets available');
        
        // Need to accoount for the withdrawn assets, they are no longer available
        //  in the employee pool
        vestingAssets += amount;
        distributer.mint(msg.sender, amount);
        emit LogWithdrawal(msg.sender, amount);
    }

    /// @notice claim an amount of tokens
    /// @param amount amount to be claimed
    function claim(uint256 amount) external override {

        require(amount > 0, "claim: No amount specified");
        (uint256 unlocked, uint256 available, , ) = unlockedBalance(msg.sender);
        require(available >= amount, "claim: Not enough user assets available");

        uint256 _withdrawn = unlocked - available + amount;
        EmployeePosition storage ep = employeePositions[msg.sender];
        ep.withdrawn = _withdrawn;
        distributer.mint(msg.sender, amount);
        emit LogClaimed(msg.sender, amount, _withdrawn, available - amount);
    }

    /// @notice stops an employees vesting position
    /// @param employee employees account
    function stopVesting(address employee) external onlyOwner {
        (uint256 unlocked, uint256 available, uint256 startTime, ) = unlockedBalance(employee);
        require(startTime > 0, 'stopVesting: No position for user');
        EmployeePosition storage ep = employeePositions[employee];
        vestingAssets -= ep.total - unlocked;
        ep.stopTime = block.timestamp;
        ep.total = unlocked;
        emit LogStoppedVesting(employee, unlocked, available);
    }

    /// @notice see the amount of vested assets the account has accumulated
    /// @param account Account to get vested amount for
    function unlockedBalance(address account)
        internal
        view
        override
        returns ( uint256, uint256, uint256, uint256 )
    {
        EmployeePosition storage ep = employeePositions[account];
        uint256 startTime = ep.startTime;
        if (block.timestamp < startTime + VESTING_CLIFF) {
            return (0, 0, startTime, startTime + VESTING_TIME);
        }
        uint256 unlocked;
        uint256 available;
        uint256 stopTime = ep.stopTime;
        uint256 _endTime = startTime + VESTING_TIME;
        uint256 total = ep.total;
        if (stopTime > 0) {
            unlocked = total;
            _endTime = stopTime;
        } else if (block.timestamp < _endTime) {
            unlocked = total * (block.timestamp - startTime) / (VESTING_TIME);
        } else {
            unlocked = total;
        }
        available = unlocked - ep.withdrawn;
        return (unlocked, available, startTime, _endTime);
    }

    /// @notice Get total size of position, vested + vesting
    /// @param account target account
    function totalBalance(address account) external view override returns (uint256 balance) {
        EmployeePosition storage ep = employeePositions[account];
        balance = ep.total;
    }
}
