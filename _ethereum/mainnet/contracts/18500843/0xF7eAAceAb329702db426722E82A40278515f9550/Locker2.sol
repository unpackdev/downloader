// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.19;

import "./SafeERC20.sol";

interface IEscrow {
    function lock(
        address _account,
        uint256 _amount,
        uint256 _weeks
    ) external returns (bool);

    function extendLock(
        uint256 _amount,
        uint256 _weeks,
        uint256 _newWeeks
    ) external returns (bool);

    function freeze() external;
}

contract YLocker {
    using SafeERC20 for IERC20;

    /// @notice Max lock for vePRISMA is one year.
    uint256 public constant MAX_LOCK_WEEKS = 52;

    /// @notice Address of the Prisma locker contract
    address public constant escrow = 0x3f78544364c3eCcDCe4d9C89a630AEa26122829d;

    /// @notice Prisma token address
    address public constant token = 0xdA47862a83dac0c112BA89c6abC2159b95afd71C;

    /// @notice Address of our strategy proxy. Outside of governance, the only address that can call this contract.
    address public proxy;

    /// @notice Governance has all the power here.
    address public governance = 0x4444AAAACDBa5580282365e25b16309Bd770ce4a;

    /// @notice Governance transfer is a two-step process. Only the pendingGovernance address can accept new gov role.
    address public pendingGovernance;

    // events
    event GovernanceUpdated(address indexed goverance);
    event ProxyUpdated(address indexed proxy);

    function init() external {
        require(msg.sender == governance, "!authorized");
        IERC20(token).approve(escrow, type(uint256).max);
    }

    /**
     *  @notice Lock our total balance of PRISMA for max time (52 weeks).
     *  @dev May only be called by governance or proxy.
     */
    function lock() external {
        require(msg.sender == proxy || msg.sender == governance, "!authorized");
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IEscrow(escrow).lock(
                address(this),
                balance / 10**18,
                MAX_LOCK_WEEKS
            );
        }
    }

    /**
     *  @notice Extend the length of an existing lock to max.
     *  @dev May only be called by governance role.
     *  @param _amount Amount of tokens to extend the lock for.
     *  @param _weeks The number of weeks of the lock to extend.
     */
    function maxExtendLock(uint256 _amount, uint256 _weeks) external {
        require(msg.sender == proxy || msg.sender == governance, "!authorized");
        IEscrow(escrow).extendLock(_amount, _weeks, MAX_LOCK_WEEKS);
    }

    /**
     *  @notice Freeze our vePRISMA lock at 52 weeks to avoid extending each week.
     *  @dev May only be called by governance or proxy.
     */
    function freeze() external {
        require(msg.sender == proxy || msg.sender == governance, "!authorized");
        IEscrow(escrow).freeze();
    }

    /**
     *  @notice Set our strategy proxy address.
     *  @dev May only be called by governance role.
     *  @param _proxy Address of new proxy contract.
     */
    function setProxy(address _proxy) external {
        require(msg.sender == governance, "!authorized");
        proxy = _proxy;
        emit ProxyUpdated(_proxy);
    }

    /**
     *  @notice Set our governance address. Step 1 of 2.
     *  @dev May only be called by current governance role.
     *  @param _governance Address of new governance.
     */
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!authorized");
        pendingGovernance = _governance;
    }

    /**
     *  @notice Accept governance role from new governance address. Step 2 of 2.
     *  @dev May only be called by current pendingGovernance role.
     */
    function acceptGovernance() external {
        address _pendingGovernance = pendingGovernance;
        require(msg.sender == _pendingGovernance, "!authorized");
        governance = _pendingGovernance;
        pendingGovernance = address(0);
        emit GovernanceUpdated(_pendingGovernance);
    }

    /**
     *  @notice Use to execute arbitrary bytecode, even if it reverts.
     *  @dev May only be called by governance or proxy.
     *  @param _to Address this call is targeting.
     *  @param _value Ether value, if needed.
     *  @param _data Bytecode to be executed.
     */
    function execute(
        address payable _to,
        uint256 _value,
        bytes calldata _data
    ) external payable returns (bool success, bytes memory result) {
        (success, result) = _execute(_to, _value, _data);
    }

    /**
     *  @notice Use to execute arbitrary bytecode, and fail on reverts.
     *  @dev May only be called by governance or proxy.
     *  @param _to Address this call is targeting.
     *  @param _value Ether value, if needed.
     *  @param _data Bytecode to be executed.
     */
    function safeExecute(
        address payable _to,
        uint256 _value,
        bytes calldata _data
    ) external payable returns (bool success, bytes memory result) {
        (success, result) = _execute(_to, _value, _data);
        require(success, "call failed");
    }

    function _execute(
        address payable _to,
        uint256 _value,
        bytes calldata _data
    ) internal returns (bool success, bytes memory result) {
        require(msg.sender == proxy || msg.sender == governance, "!authorized");
        (success, result) = _to.call{value: _value}(_data);
    }

    receive() external payable {}
}
