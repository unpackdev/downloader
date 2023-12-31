pragma solidity 0.8.18;

import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Admin.sol";

/**
 * @title FeeOperator
 * @notice Fee collectors collects fees from contract
 */
abstract contract FeeOperator is Admin, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Mapping of fee collector to whether it is a fee collector
    mapping(address => bool) private _feeCollectors;

    // ============ Events ============
    /**
     * @notice Emitted when a fee collector is added
     * @param feeCollector address of the fee collector
     */
    event FeeCollectorAdded(address feeCollector);
    /**
     * @notice Emitted when a fee collector is removed
     * @param feeCollector address of the fee collector
     */
    event FeeCollectorRemoved(address feeCollector);

    // Errors
    error NotFeeCollector();
    error InvalidFeeCollector();
    error AlreadyFeeCollector();

    // ============ Modifiers ============
    /**
     * @dev Throws if called by any account other than the fee collector
     */
    modifier onlyFeeCollector() {
        if (!isFeeCollector(msg.sender)) {
            revert NotFeeCollector();
        }
        _;
    }

    // ============ Constructor ============
    /**
     * @notice Initializes the contract
     * set the deployer as the first fee collector
     */
    constructor() {
        _feeCollectors[msg.sender] = true;
    }

    // ============ External Functions ============
    /**
     * @notice Collects fees from contract
     * @param token token address
     * @return bool true if success
     */
    function collectFees(address token) external nonReentrant onlyFeeCollector returns (bool) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, balance);
        return true;
    }

    /**
     * @notice Adds a fee collector
     * @param feeCollector address of the fee collector
     */
    function addFeeCollector(address feeCollector) external onlyAdmin {
        if (feeCollector == address(0)) {
            revert InvalidFeeCollector();
        }
        if (isFeeCollector(feeCollector)) {
            revert AlreadyFeeCollector();
        }
        _feeCollectors[feeCollector] = true;
        emit FeeCollectorAdded(feeCollector);
    }

    /**
     * @notice Removes a fee collector
     * @param feeCollector address of the fee collector
     */
    function removeFeeCollector(address feeCollector) external onlyAdmin {
        if (!isFeeCollector(feeCollector)) {
            revert NotFeeCollector();
        }
        _feeCollectors[feeCollector] = false;
        emit FeeCollectorRemoved(feeCollector);
    }

     /**
     * @notice Returns the fee amount of each token
     * @param token token address
     * @return uint256 token balance
     */
    function getFeeAmounts(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @notice Returns whether an account is a fee collector
     * @param account address of the account
     * @return bool true if account is a fee collector
     */
    function isFeeCollector(address account) public view returns (bool) {
        return _feeCollectors[account];
    }
}