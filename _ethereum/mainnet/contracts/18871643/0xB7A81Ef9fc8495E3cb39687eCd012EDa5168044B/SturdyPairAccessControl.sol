// SPDX-License-Identifier: ISC
pragma solidity ^0.8.21;

// ==================== SturdyPairAccessControl =====================

import "./Ownable2Step.sol";
import "./Timelock2Step.sol";
import "./SturdyPairAccessControlErrors.sol";

/// @title SturdyPairAccessControl
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An abstract contract which contains the access control logic for SturdyPair
abstract contract SturdyPairAccessControl is Timelock2Step, Ownable2Step, SturdyPairAccessControlErrors {
    // Deployer
    address public immutable DEPLOYER_ADDRESS;

    // Admin contracts
    address public circuitBreakerAddress;

    // access control
    uint256 public borrowLimit = type(uint256).max;

    uint256 public depositLimit = type(uint256).max;

    bool public isRepayPaused;
    bool public isRepayAccessControlRevoked;

    bool public isWithdrawPaused;
    bool public isWithdrawAccessControlRevoked;

    bool public isLiquidatePaused;
    bool public isLiquidateAccessControlRevoked;

    bool public isInterestPaused;

    /// @param _immutables abi.encode(address _circuitBreakerAddress, address _comptrollerAddress, address _timelockAddress)
    constructor(bytes memory _immutables) Timelock2Step() Ownable2Step() {
        // Handle Immutables Configuration
        (address _circuitBreakerAddress, address _comptrollerAddress, address _timelockAddress) = abi.decode(
            _immutables,
            (address, address, address)
        );
        _setTimelock(_timelockAddress);
        _transferOwnership(_comptrollerAddress);

        // Deployer contract
        DEPLOYER_ADDRESS = msg.sender;
        circuitBreakerAddress = _circuitBreakerAddress;
    }

    // ============================================================================================
    // Functions: Access Control
    // ============================================================================================

    function _requireProtocolOrOwner() internal view {
        if (
            msg.sender != circuitBreakerAddress &&
            msg.sender != owner() &&
            msg.sender != DEPLOYER_ADDRESS &&
            msg.sender != timelockAddress
        ) {
            revert OnlyProtocolOrOwner();
        }
    }

    function _requireTimelockOrOwner() internal view {
        if (msg.sender != owner() && msg.sender != timelockAddress) {
            revert OnlyTimelockOrOwner();
        }
    }

    /// @notice The ```SetBorrowLimit``` event is emitted when the borrow limit is set
    /// @param limit The new borrow limit
    event SetBorrowLimit(uint256 limit);

    function _setBorrowLimit(uint256 _limit) internal {
        borrowLimit = _limit;
        emit SetBorrowLimit(_limit);
    }

    /// @notice The ```SetDepositLimit``` event is emitted when the deposit limit is set
    /// @param limit The new deposit limit
    event SetDepositLimit(uint256 limit);

    function _setDepositLimit(uint256 _limit) internal {
        depositLimit = _limit;
        emit SetDepositLimit(_limit);
    }

    /// @notice The ```RevokeRepayAccessControl``` event is emitted when repay access control is revoked
    event RevokeRepayAccessControl();

    function _revokeRepayAccessControl() internal {
        isRepayAccessControlRevoked = true;
        emit RevokeRepayAccessControl();
    }

    /// @notice The ```PauseRepay``` event is emitted when repay is paused or unpaused
    /// @param isPaused The new paused state
    event PauseRepay(bool isPaused);

    function _pauseRepay(bool _isPaused) internal {
        isRepayPaused = _isPaused;
        emit PauseRepay(_isPaused);
    }

    /// @notice The ```RevokeWithdrawAccessControl``` event is emitted when withdraw access control is revoked
    event RevokeWithdrawAccessControl();

    function _revokeWithdrawAccessControl() internal {
        isWithdrawAccessControlRevoked = true;
        emit RevokeWithdrawAccessControl();
    }

    /// @notice The ```PauseWithdraw``` event is emitted when withdraw is paused or unpaused
    /// @param isPaused The new paused state
    event PauseWithdraw(bool isPaused);

    function _pauseWithdraw(bool _isPaused) internal {
        isWithdrawPaused = _isPaused;
        emit PauseWithdraw(_isPaused);
    }

    /// @notice The ```RevokeLiquidateAccessControl``` event is emitted when liquidate access control is revoked
    event RevokeLiquidateAccessControl();

    function _revokeLiquidateAccessControl() internal {
        isLiquidateAccessControlRevoked = true;
        emit RevokeLiquidateAccessControl();
    }

    /// @notice The ```PauseLiquidate``` event is emitted when liquidate is paused or unpaused
    /// @param isPaused The new paused state
    event PauseLiquidate(bool isPaused);

    function _pauseLiquidate(bool _isPaused) internal {
        isLiquidatePaused = _isPaused;
        emit PauseLiquidate(_isPaused);
    }

    /// @notice The ```PauseInterest``` event is emitted when interest is paused or unpaused
    /// @param isPaused The new paused state
    event PauseInterest(bool isPaused);

    function _pauseInterest(bool _isPaused) internal {
        isInterestPaused = _isPaused;
        emit PauseInterest(_isPaused);
    }

    /// @notice The ```SetCircuitBreaker``` event is emitted when the circuit breaker address is set
    /// @param oldCircuitBreaker The old circuit breaker address
    /// @param newCircuitBreaker The new circuit breaker address
    event SetCircuitBreaker(address oldCircuitBreaker, address newCircuitBreaker);

    /// @notice The ```_setCircuitBreaker``` function is called to set the circuit breaker address
    /// @param _newCircuitBreaker The new circuit breaker address
    function _setCircuitBreaker(address _newCircuitBreaker) internal {
        address oldCircuitBreaker = circuitBreakerAddress;
        circuitBreakerAddress = _newCircuitBreaker;
        emit SetCircuitBreaker(oldCircuitBreaker, _newCircuitBreaker);
    }

    /// @notice The ```setCircuitBreaker``` function is called to set the circuit breaker address
    /// @param _newCircuitBreaker The new circuit breaker address
    function setCircuitBreaker(address _newCircuitBreaker) external virtual {
        _requireTimelock();
        _setCircuitBreaker(_newCircuitBreaker);
    }
}
